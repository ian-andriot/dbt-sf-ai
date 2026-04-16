{% materialization semantic_view, adapter='snowflake' -%}
  {% set original_query_tag = set_query_tag() %}
  {% do dbt_semantic_view.snowflake__create_or_replace_semantic_view() %}
  {% set target_relation = this.incorporate(type='view') %}
  {% do unset_query_tag(original_query_tag) %}
  {% do return({'relations': [target_relation]}) %}
{%- endmaterialization %}
