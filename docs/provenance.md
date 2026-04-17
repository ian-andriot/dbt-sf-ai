# Provenance

This package was scaffolded as a dbt package named `sf_ai` for the `sf-ai` repository.

Upstream references:

- Snowflake Labs `dbt_semantic_view` package, used as a dependency for semantic-view materialization support.
- Snowflake SQL DDL documentation for `CREATE AGENT`.
- Snowflake SQL DDL documentation for `CREATE SNOWFLAKE.ML.FORECAST`.
- Snowflake SQL DDL documentation for `CREATE SNOWFLAKE.ML.ANOMALY_DETECTION`.
- Snowflake SQL DDL documentation for `CREATE SNOWFLAKE.ML.CLASSIFICATION`.

Semantic-view support is provided directly by `Snowflake-Labs/dbt_semantic_view`; this package does not define or wrap the `semantic_view` materialization.

The upstream package is Apache-2.0 licensed. See `NOTICE`.
