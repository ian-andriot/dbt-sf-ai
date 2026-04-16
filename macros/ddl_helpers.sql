{% macro raise_if_replace_and_exists(or_replace, if_not_exists) -%}
  {%- if or_replace and if_not_exists -%}
    {{ exceptions.raise_compiler_error("sf_ai materializations cannot set both or_replace=true and if_not_exists=true.") }}
  {%- endif -%}
{%- endmacro %}

{% macro create_modifier(or_replace=false, if_not_exists=false) -%}
  {{ sf_ai.raise_if_replace_and_exists(or_replace, if_not_exists) }}
  {%- if or_replace -%}
    or replace
  {%- endif -%}
{%- endmacro %}

{% macro if_not_exists_clause(if_not_exists=false) -%}
  {%- if if_not_exists -%}
    if not exists
  {%- endif -%}
{%- endmacro %}

{% macro sql_string(value) -%}
  '{{ (value | string).replace("'", "''") }}'
{%- endmacro %}

{% macro comment_clause(comment) -%}
  {%- if comment is not none and comment != '' -%}
    comment = {{ sf_ai.sql_string(comment) }}
  {%- endif -%}
{%- endmacro %}

{% macro tag_clause(tags) -%}
  {%- if tags is mapping and tags | length > 0 -%}
    with tag (
      {%- for tag_name, tag_value in tags.items() -%}
        {{ tag_name }} = {{ sf_ai.sql_string(tag_value) }}{{ "," if not loop.last }}
      {%- endfor -%}
    )
  {%- endif -%}
{%- endmacro %}

{% macro profile_clause(profile) -%}
  {%- if profile is not none and profile != '' -%}
    {%- if profile is mapping -%}
      profile = {{ sf_ai.sql_string(profile | tojson) }}
    {%- else -%}
      profile = {{ sf_ai.sql_string(profile) }}
    {%- endif -%}
  {%- endif -%}
{%- endmacro %}

{% macro relation(identifier) -%}
  {{ return(api.Relation.create(identifier=identifier, schema=schema, database=database, type='view')) }}
{%- endmacro %}

{% macro require_config(config_name, value) -%}
  {%- if value is none or value == '' -%}
    {{ exceptions.raise_compiler_error("Missing required config `" ~ config_name ~ "`.") }}
  {%- endif -%}
{%- endmacro %}

{% macro input_data(sql, input_data) -%}
  {%- if input_data is not none and input_data != '' -%}
    {{ input_data }}
  {%- else -%}
    {%- set body = sql | trim -%}
    {%- if body == '' -%}
      {{ exceptions.raise_compiler_error("Provide `input_data` config or a model SQL body containing a Snowflake reference expression.") }}
    {%- endif -%}
    {{ body }}
  {%- endif -%}
{%- endmacro %}

{% macro run_create_statement(target_relation, create_sql) -%}
  {{ run_hooks(pre_hooks) }}

  {% call statement('main') -%}
    {{ create_sql }}
  {%- endcall %}

  {{ run_hooks(post_hooks) }}

  {{ return({'relations': [target_relation]}) }}
{%- endmacro %}
