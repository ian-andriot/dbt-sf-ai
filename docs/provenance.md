# Provenance

This package was scaffolded as a dbt package named `sf_ai` for the `sf-ai` repository.

Upstream references:

- Snowflake Labs `dbt_semantic_view` package, used as a dependency and source for semantic-view helper/test patterns.
- Snowflake SQL DDL documentation for `CREATE AGENT`.
- Snowflake SQL DDL documentation for `CREATE SNOWFLAKE.ML.FORECAST`.
- Snowflake SQL DDL documentation for `CREATE SNOWFLAKE.ML.ANOMALY_DETECTION`.
- Snowflake SQL DDL documentation for `CREATE SNOWFLAKE.ML.CLASSIFICATION`.

Referenced elements from `Snowflake-Labs/dbt_semantic_view`:

- The `semantic_view` materialization lifecycle delegates to `dbt_semantic_view.snowflake__create_or_replace_semantic_view`.
- Integration tests use the same style of compiled DDL and object-behavior assertions, but target this package's custom Snowflake AI materializations.

The adapted upstream package is Apache-2.0 licensed. See `NOTICE`.
