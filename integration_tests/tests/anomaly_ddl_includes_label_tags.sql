{{
  config(
    materialized='test',
    timestamp_colname='ORDER_TS',
    target_colname='REVENUE',
    label_colname='IS_ANOMALY',
    object_tags={"GOVERNANCE.TEST_TAG": "sf-ai"}
  )
}}

{% set relation = api.Relation.create(database=target.database, schema=target.schema, identifier='TEST_ANOMALY') %}
{% set ddl = sf_ai.sf_ai__get_create_anomaly_detection_sql(
  relation,
  "TABLE(" ~ ref('base_table') ~ ")",
  timestamp_colname='ORDER_TS',
  target_colname='REVENUE',
  label_colname='IS_ANOMALY',
  object_tags={"GOVERNANCE.TEST_TAG": "sf-ai"}
) | lower %}
{% set ddl_sql = sf_ai.sf_ai__sql_string(ddl) %}

select 'anomaly ddl missing expected clauses' as error_message
where position('create or replace snowflake.ml.anomaly_detection' in {{ ddl_sql }}) = 0
  or position('timestamp_colname => ''order_ts''' in {{ ddl_sql }}) = 0
  or position('target_colname => ''revenue''' in {{ ddl_sql }}) = 0
  or position('label_colname => ''is_anomaly''' in {{ ddl_sql }}) = 0
  or position('with tag (' in {{ ddl_sql }}) = 0
  or position('governance.test_tag = ''sf-ai''' in {{ ddl_sql }}) = 0
