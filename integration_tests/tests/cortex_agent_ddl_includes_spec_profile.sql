{{
  config(
    materialized='test',
    comment='test agent',
    profile={"display_name": "Test Agent", "color": "blue"}
  )
}}

{% set relation = api.Relation.create(database=target.database, schema=target.schema, identifier='TEST_AGENT') %}
{% set spec %}
models:
  orchestration: claude-4-sonnet
instructions:
  response: "Answer briefly."
{% endset %}
{% set ddl = sf_ai.snowflake__get_create_cortex_agent_sql(relation, spec, comment='test agent', profile={"display_name": "Test Agent", "color": "blue"}) | lower %}
{% set ddl_sql = sf_ai.sql_string(ddl) %}

select 'agent ddl missing expected clauses' as error_message
where position('create or replace agent' in {{ ddl_sql }}) = 0
  or position('profile =' in {{ ddl_sql }}) = 0
  or position('"display_name": "test agent"' in {{ ddl_sql }}) = 0
  or position('"color": "blue"' in {{ ddl_sql }}) = 0
  or position('from specification' in {{ ddl_sql }}) = 0
  or position('models:' in {{ ddl_sql }}) = 0
