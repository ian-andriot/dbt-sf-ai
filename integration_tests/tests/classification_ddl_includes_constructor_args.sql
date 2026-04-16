{{
  config(
    materialized='test',
    target_colname='CHURNED',
    config_object="OBJECT_CONSTRUCT('evaluate', true)",
    if_not_exists=true,
    or_replace=false
  )
}}

{% set relation = api.Relation.create(database=target.database, schema=target.schema, identifier='TEST_CLASSIFICATION') %}
{% set ddl = sf_ai.sf_ai__get_create_classification_sql(
  relation,
  "TABLE(" ~ ref('base_table') ~ ")",
  target_colname='CHURNED',
  config_object="OBJECT_CONSTRUCT('evaluate', true)",
  if_not_exists=true,
  or_replace=false
) | lower %}
{% set ddl_sql = sf_ai.sf_ai__sql_string(ddl) %}

select 'classification ddl missing expected clauses' as error_message
where position('create' in {{ ddl_sql }}) = 0
  or position('snowflake.ml.classification' in {{ ddl_sql }}) = 0
  or position('if not exists' in {{ ddl_sql }}) = 0
  or position('input_data =>' in {{ ddl_sql }}) = 0
  or position('target_colname => ''churned''' in {{ ddl_sql }}) = 0
  or position('config_object => object_construct(''evaluate'', true)' in {{ ddl_sql }}) = 0
