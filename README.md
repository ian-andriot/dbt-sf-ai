# sf-ai

`sf-ai` is a dbt package for managing Snowflake AI objects with dbt materializations backed by Snowflake SQL DDL.

It provides:

- `semantic_view`, as a small shim around Snowflake Labs' `dbt_semantic_view` package.
- `cortex_agent`, backed by `CREATE OR REPLACE AGENT ... FROM SPECIFICATION`.
- `forecast`, backed by `CREATE OR REPLACE SNOWFLAKE.ML.FORECAST`.
- `anomaly`, backed by `CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION`.
- `classification`, backed by `CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION`.

## Install

Add this package to a consuming dbt project's `packages.yml`:

```yaml
packages:
  - git: "https://github.com/<your-org>/sf-ai.git"
    revision: main
```

Then run:

```shell
dbt deps
```

`sf-ai` declares `Snowflake-Labs/dbt_semantic_view` `1.0.3` as a dependency.

## Semantic View

The semantic-view materialization is intentionally a shim. Write the Snowflake semantic view DDL body in the model SQL:

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

## DDL Options

Common configs:

- `input_data`: raw Snowflake reference expression. If omitted, the materialization uses the model SQL body.
- `comment`: emitted as `COMMENT = '<comment>'`.
- `object_tags`: mapping emitted as `WITH TAG (...)`.

All custom materializations emit `CREATE OR REPLACE` DDL so definitions converge the same way normal dbt relation materializations do.

The Snowflake ML Function objects managed by `forecast`, `anomaly`, and `classification` are not Snowflake Model Registry models. Snowflake's Model Registry documentation states that models trained with ML Functions, such as `FORECAST`, do not appear in the registry. If you need retention instead of replacement, use one of these patterns:

- Version the object name itself with dbt aliases, for example `alias='revenue_forecast_v20260416'`.
- For true registry/version/alias workflows, use Snowpark ML plus the Snowflake Model Registry rather than these SQL ML Function materializations.

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
