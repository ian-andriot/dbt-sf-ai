# sf-ai

`sf-ai` is a dbt package for managing Snowflake AI objects with dbt materializations backed by Snowflake SQL DDL and the Snowflake Model Registry.

It provides:

- `semantic_view`, provided directly by the Snowflake Labs `dbt_semantic_view` dependency.
- `cortex_agent`, backed by `CREATE OR REPLACE AGENT ... FROM SPECIFICATION`.
- `cortex_search_service`, backed by `CREATE OR REPLACE CORTEX SEARCH SERVICE`.
- `stored_procedure`, backed by `CREATE OR REPLACE PROCEDURE` for SQL and Python models.
- `forecast`, backed by `CREATE OR REPLACE SNOWFLAKE.ML.FORECAST`.
- `anomaly`, backed by `CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION`.
- `classification`, backed by `CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION`.
- `python_model`, backed by the Snowflake Model Registry Python API.

## Install

Add this package to a consuming dbt project's `packages.yml`:

```yaml
packages:
  - git: "https://github.com/ian-andriot/dbt-sf-ai.git"
    revision: v0.1.0
```

Then run:

```shell
dbt deps
```

`sf-ai` declares `Snowflake-Labs/dbt_semantic_view` `1.0.3` as a dependency.

## Semantic View

The semantic-view materialization is provided directly by `Snowflake-Labs/dbt_semantic_view`. Write the Snowflake semantic view DDL body in the model SQL:

```sql
{{ config(materialized='semantic_view') }}

tables (
  ORDERS as {{ ref('orders') }} primary key (ORDER_ID)
)
dimensions (
  ORDERS.ORDER_DATE as ORDER_DATE
)
metrics (
  ORDERS.ORDER_COUNT as count(ORDER_ID)
)
comment = 'Orders semantic view'
```

## Cortex Agent

Put the agent YAML specification in the model body. Optional `profile` config maps to the Snowflake DDL clause.

```sql
{{
  config(
    materialized='cortex_agent',
    profile={"display_name": "Revenue Analyst", "color": "blue"}
  )
}}

models:
  orchestration: claude-4-sonnet
instructions:
  response: "Answer with concise business context."
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "RevenueAnalyst"
      description: "Converts revenue questions to SQL"
tool_resources:
  RevenueAnalyst:
    semantic_view: "{{ ref('revenue_semantic_view') }}"
```

## Cortex Search Service

Use `cortex_search_service` when the model SQL body is the source query to index. The materialization emits `CREATE OR REPLACE CORTEX SEARCH SERVICE` and expects the source query in the model body.

```sql
{{
  config(
    materialized='cortex_search_service',
    search_column='TEXT',
    primary_key=['DOC_ID'],
    attributes=['CATEGORY'],
    target_lag='1 day',
    initialize='ON_CREATE'
  )
}}

select
  doc_id,
  text,
  category
from {{ ref('policy_documents') }}
```

Required configs:

- `search_column`
- `attributes`
- `warehouse` or a target profile with `warehouse`
- `target_lag`

Supported optional configs:

- `primary_key`
- `embedding_model`
- `refresh_mode`
- `initialize`
- `full_index_build_interval_days`
- `request_logging`

You can use the resulting service in a Cortex Agent search tool by referencing it in the agent specification:

```yaml
tools:
  - tool_spec:
      type: "cortex_search"
      name: "PolicySearch"
      description: "Searches refund and support policies"
tool_resources:
  PolicySearch:
    name: "{{ ref('cortex_search_service_example') }}"
    max_results: 3
    title_column: "DOC_ID"
    id_column: "DOC_ID"
    columns_and_descriptions:
      TEXT:
        description: "Policy text"
        type: "string"
        searchable: true
        filterable: false
      CATEGORY:
        description: "Policy category such as refund or support"
        type: "string"
        searchable: false
        filterable: true
```

## Stored Procedures

Use `stored_procedure` to create Snowflake stored procedures from either SQL or Python dbt models. The model language determines the procedure language.

SQL models use the model body as the Snowflake Scripting procedure body:

```sql
{{
  config(
    materialized='stored_procedure',
    arguments=['NAME STRING'],
    returns='TABLE (GREETING STRING)',
    execute_as='CALLER'
  )
}}

DECLARE
  res RESULTSET;
BEGIN
  res := (select 'hello ' || :NAME as greeting);
  RETURN TABLE(res);
END
```

Python models keep dbt's standard two-argument `model(dbt, session)` contract. If the model returns a callable, the materialization invokes that callable with the stored procedure arguments:

```python
def model(dbt, session):
    dbt.config(
        materialized="stored_procedure",
        arguments=["NAME STRING"],
        returns="TABLE (GREETING STRING)",
        packages=["snowflake-snowpark-python"],
        execute_as="CALLER",
    )

    def run(name):
        return session.create_dataframe([[f"hello {name}"]], schema=["GREETING"])

    return run
```

Required configs:

- `returns`

Common optional configs:

- `arguments`: string, list of raw argument strings, or list of mappings with `name`, `type` or `data_type`, optional `mode`, and optional `default`.
- `copy_grants`
- `secure`
- `temporary`
- `null_input_behavior`
- `volatility`
- `execute_as`

Python-only optional configs:

- `python_version`, defaulting to `3.10`
- `packages`, defaulting to `['snowflake-snowpark-python']`
- `imports`
- `external_access_integrations`
- `secrets`
- `artifact_repository`

Stored procedures that return a static table schema can be used in downstream dbt SQL models with Snowflake's `TABLE(...)` syntax:

```sql
select *
from table({{ ref('python_stored_procedure_example') }}('dbt'))
```

The materialization wraps procedure bodies in Snowflake `$$` delimiters. Avoid raw `$$` inside stored procedure bodies, because Snowflake will treat it as the end of the body literal.

## Forecast Model

The model body should be a Snowflake reference expression such as `TABLE(...)`, `SYSTEM$REFERENCE(...)`, or `SYSTEM$QUERY_REFERENCE(...)`. You can also pass `input_data` as a config value.

```sql
{{
  config(
    materialized='forecast',
    timestamp_colname='ORDER_DATE',
    target_colname='REVENUE',
    series_colname='REGION',
    config_object="OBJECT_CONSTRUCT('method', 'fast')"
  )
}}

TABLE({{ ref('daily_revenue') }})
```

## Anomaly Model

```sql
{{
  config(
    materialized='anomaly',
    timestamp_colname='EVENT_TS',
    target_colname='METRIC_VALUE',
    label_colname='IS_ANOMALY',
    config_object="OBJECT_CONSTRUCT('evaluate', true)"
  )
}}

TABLE({{ ref('metric_training_data') }})
```

## Classification Model

```sql
{{
  config(
    materialized='classification',
    target_colname='CHURNED',
    config_object="OBJECT_CONSTRUCT('evaluate', true)"
  )
}}

TABLE({{ ref('customer_training_data') }})
```

## Python Model Registry

Use `python_model` when the dbt model trains or loads a Python model and registers a new Snowflake Model Registry version. The materialization creates an append-only history table at the dbt model relation and then logs the returned Python model into the registry.

```python
def model(dbt, session):
    dbt.config(
        materialized="python_model",
        packages=["snowflake-ml-python", "scikit-learn", "pandas"],
        aliases=["dev"],
        set_default=True,
        metrics={"accuracy": 0.93},
        comment="Customer churn classifier",
    )

    import pandas as pd
    from sklearn.ensemble import RandomForestClassifier

    training_data = dbt.ref("customer_training_data").to_pandas()
    x_train = training_data[["TENURE", "REVENUE"]]
    y_train = training_data["CHURNED"]

    classifier = RandomForestClassifier(n_estimators=50, random_state=7)
    classifier.fit(x_train, y_train)

    return {
        "model": classifier,
        "sample_input_data": pd.DataFrame({"TENURE": [12], "REVENUE": [250.0]}),
        "metrics": {"accuracy": 0.93},
        "metadata": {"training_source": "customer_training_data"},
    }
```

Defaults:

- `model_name`: the dbt model FQN joined with `__`.
- `version_name`: `VYYYYMMDD_HHMMSS_microseconds_UTC`, generated at Python runtime unless provided.
- `registry_database` and `registry_schema`: the active dbt target database and schema.

Promotion configs:

- `aliases`: list of Snowflake model version aliases to assign after logging.
- `set_default`: sets the logged version as the model default version.
- `registry_tags`: mapping emitted with `ALTER MODEL ... SET TAG`.

Registry logging configs:

- `registry_options`: passed to `snowflake.ml.registry.Registry`.
- `log_model_options`: passed as `options` to `Registry.log_model`.
- `conda_dependencies`, `pip_requirements`, `target_platforms`, `resource_constraint`, and `artifact_repository_map`: forwarded to `Registry.log_model` when set.

The Python model can return the model object directly or return a dictionary with `model`, `sample_input_data`, `signatures`, `metrics`, `metadata`, `comment`, `model_name`, `version_name`, and the forwarded registry options above. Payload values override matching dbt configs for that run.

`python_model` is append-only and intentionally rejects `--full-refresh`. A user-provided `version_name` must still be unique for the model; timestamp defaults make normal dbt runs create a new registry version.

Use `registry_model_call` in downstream SQL models to resolve the latest successful registry row from the history table and emit a Snowflake model method call:

```sql
-- depends_on: {{ ref('python_model_iris') }}

select
  *,
  {{
    sf_ai.registry_model_call(
      ref('python_model_iris'),
      'predict',
      ['sepal_length', 'sepal_width', 'petal_length', 'petal_width'],
      alias='DEV'
    )
  }} as prediction
from iris_inference_input
```

The macro uses the latest `status = 'success'` row in the history relation and renders `MODEL(<registry_name>, <alias_or_version>)!<method>(...)`. Add an explicit `depends_on` line when the only dependency is inside the macro call.

## DDL Options

Common configs for the SQL DDL materializations:

- `input_data`: raw Snowflake reference expression. If omitted, the materialization uses the model SQL body.
- `comment`: emitted as `COMMENT = '<comment>'`.
- `object_tags`: mapping emitted as `WITH TAG (...)`.

The SQL DDL materializations emit `CREATE OR REPLACE` DDL so definitions converge the same way normal dbt relation materializations do.

The Snowflake ML Function objects managed by `forecast`, `anomaly`, and `classification` are not Snowflake Model Registry models. Snowflake's Model Registry documentation states that models trained with ML Functions, such as `FORECAST`, do not appear in the registry. If you need retention instead of replacement, use one of these patterns:

- Version the object name itself with dbt aliases, for example `alias='revenue_forecast_v20260416'`.
- For true registry/version/alias workflows, use `python_model` with Snowpark ML and the Snowflake Model Registry.

## Development

This repository follows a dbt package scaffold:

- package metadata in `dbt_project.yml`
- macros under `macros/`
- integration fixtures under `integration_tests/`
- dependency declaration in `packages.yml`
- provenance in `NOTICE` and `docs/provenance.md`

Run checks:

```shell
dbt deps
dbt parse
dbt build --target snowflake
```

Run the opt-in AI integration path:

```shell
dbt build --target snowflake --vars '{"sf_ai_enable_ai_integration_tests": true}'
```

That path creates the example Snowflake AI objects and materializes downstream result tables:

- `forecast_predictions` calls `{{ ref('forecast_example') }}!FORECAST(...)`.
- `anomaly_detections` calls `{{ ref('anomaly_example') }}!DETECT_ANOMALIES(...)`.
- `classification_predictions` calls `{{ ref('classification_example') }}!PREDICT(...)`.
- `cortex_agent_responses` calls `SNOWFLAKE.CORTEX.DATA_AGENT_RUN(...)` with the `cortex_agent_example` relation.

Run the opt-in registry fixture separately:

```shell
dbt build --target snowflake --select python_model_iris+ --vars '{"sf_ai_enable_registry_integration_tests": true}'
```

That path creates an Iris classifier version, appends one row to the `python_model_iris` history table, materializes SQL inference results through `registry_model_call`, and runs the registry tests.


Run the opt-in Cortex Search integration path separately:

```shell
dbt run --target snowflake --select +cortex_agent_with_search_example --vars '{"sf_ai_enable_cortex_search_integration_tests": true}'
```

On accounts with Cortex Search enabled for agent execution, you can run the full end-to-end search-agent assertion with:

```shell
dbt build --target snowflake --select +cortex_agent_with_search_example+ --vars '{"sf_ai_enable_cortex_search_integration_tests": true}'
```

Trial accounts can create the search service and agent object, but Snowflake currently rejects the search-tool `DATA_AGENT_RUN` path with `Access denied for trial accounts.`


Run the opt-in stored procedure integration path separately:

```shell
dbt build --target snowflake --select sql_stored_procedure_example+ python_stored_procedure_example+ --vars '{"sf_ai_enable_procedure_integration_tests": true}'
```

That path creates SQL and Python stored procedures, creates a Cortex Agent that references both procedures as custom tools, materializes result tables from `TABLE(procedure(...))`, and runs invocation assertions.
