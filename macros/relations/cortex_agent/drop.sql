{% macro snowflake__get_drop_cortex_agent_sql(relation) -%}
  drop agent if exists {{ relation }}
{%- endmacro %}
