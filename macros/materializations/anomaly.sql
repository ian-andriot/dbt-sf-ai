{% materialization anomaly, adapter='snowflake' -%}
  {% set original_query_tag = set_query_tag() %}
  {% set target_relation = sf_ai.relation(model['alias']) %}
  {% set create_sql = sf_ai.snowflake__get_create_anomaly_detection_sql(target_relation, sql) %}
  {% do sf_ai.run_create_statement(target_relation, create_sql) %}
  {% do unset_query_tag(original_query_tag) %}
  {% do return({'relations': [target_relation]}) %}
{%- endmaterialization %}
