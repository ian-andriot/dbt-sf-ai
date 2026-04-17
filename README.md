# sf-ai

`sf-ai` is a dbt package for managing Snowflake AI objects with dbt materializations backed by Snowflake SQL DDL and the Snowflake Model Registry.

It provides:

- `semantic_view`, provided directly by the Snowflake Labs `dbt_semantic_view` dependency.
- `cortex_agent`, backed by `CREATE OR REPLACE AGENT ... FROM SPECIFICATION`.
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

Put the agent YAML specification in the model body. Optional `comment` and `profile` configs map to the Snowflake DDL clauses.

```sql
{{
  config(
    materialized='cortex_agent',
    comment='Revenue analyst agent',
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

## Forecast Model

The model body should be a Snowflake reference expression such as `TABLE(...)`, `SYSTEM$REFERENCE(...)`, or `SYSTEM$QUERY_REFERENCE(...)`. You can also pass `input_data` as a config value.

```sql
{{
  config(
    materialized='forecast',
    timestamp_colname='ORDER_DATE',
    target_colname='REVENUE',
    series_colname='REGION',
    config_object="OBJECT_CONSTRUCT('method', 'fast')",
    comment='Revenue forecast model'
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
