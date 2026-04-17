{% macro registry_model_call(history_relation, method, arguments, alias='DEFAULT') -%}
  {%- if arguments is string -%}
    {%- set argument_sql = arguments -%}
  {%- else -%}
    {%- set argument_sql = arguments | join(', ') -%}
  {%- endif -%}

  {%- if execute -%}
    {%- set registry_lookup_sql -%}
      select registry_name, version_name
      from {{ history_relation }}
      where status = 'success'
      qualify row_number() over (order by registered_at desc) = 1
    {%- endset -%}
    {%- set registry_lookup = run_query(registry_lookup_sql) -%}
    {%- if registry_lookup is none or registry_lookup.rows | length == 0 -%}
      {{ exceptions.raise_compiler_error("No successful python_model registry history row found in " ~ history_relation) }}
    {%- endif -%}
    {%- set registry_name = registry_lookup.rows[0][0] -%}
    {%- set version_ref = alias if alias is not none and alias != '' else registry_lookup.rows[0][1] -%}
    MODEL({{ registry_name }}, {{ version_ref | upper }})!{{ method }}({{ argument_sql }})
  {%- else -%}
    MODEL(SF_AI_PARSE_PLACEHOLDER, {{ (alias or 'DEFAULT') | upper }})!{{ method }}({{ argument_sql }})
  {%- endif -%}
{%- endmacro %}
