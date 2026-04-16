{% materialization cortex_agent, adapter='snowflake' -%}
  {% set original_query_tag = set_query_tag() %}
  {% set target_relation = sf_ai.sf_ai__relation(model['alias']) %}
  {% set create_sql = sf_ai.sf_ai__get_create_cortex_agent_sql(target_relation, sql) %}
  {% do sf_ai.sf_ai__run_create_statement(target_relation, create_sql) %}
  {% do unset_query_tag(original_query_tag) %}
  {% do return({'relations': [target_relation]}) %}
{%- endmaterialization %}
