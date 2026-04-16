{{
  config(
    materialized='test',
    timestamp_colname='ORDER_TS',
    target_colname='REVENUE',
    series_colname='REGION',
    config_object="OBJECT_CONSTRUCT('method', 'fast')",
    comment='test forecast'
  )
}}

{% set relation = api.Relation.create(database=target.database, schema=target.schema, identifier='TEST_FORECAST') %}
{% set ddl = sf_ai.snowflake__get_create_forecast_sql(
  relation,
  "TABLE(" ~ ref('base_table') ~ ")",
  timestamp_colname='ORDER_TS',
  target_colname='REVENUE',
  series_colname='REGION',
  config_object="OBJECT_CONSTRUCT('method', 'fast')",
  comment='test forecast'
) | lower %}
{% set ddl_sql = sf_ai.sql_string(ddl) %}

select 'forecast ddl missing expected clauses' as error_message
where position('create or replace snowflake.ml.forecast' in {{ ddl_sql }}) = 0
  or position('input_data =>' in {{ ddl_sql }}) = 0
  or position('series_colname => ''region''' in {{ ddl_sql }}) = 0
  or position('timestamp_colname => ''order_ts''' in {{ ddl_sql }}) = 0
  or position('target_colname => ''revenue''' in {{ ddl_sql }}) = 0
  or position('config_object => object_construct(''method'', ''fast'')' in {{ ddl_sql }}) = 0
  or position('comment = ''test forecast''' in {{ ddl_sql }}) = 0
