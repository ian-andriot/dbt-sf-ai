{% macro sql_string(value) -%}
  '{{ (value | string).replace("'", "''") }}'
{%- endmacro %}

{% macro object_comment(configured_comment=none) -%}
  {%- if configured_comment is not none -%}
    {%- do return(configured_comment) -%}
  {%- endif -%}
  {%- do return(model.get('description')) -%}
{%- endmacro %}

{% macro config_require_non_empty_list(config_name, value) -%}
  {%- if value is not sequence or value is string or value | length == 0 -%}
    {{ exceptions.raise_compiler_error("Missing required config `" ~ config_name ~ "`. Pass a non-empty list.") }}
  {%- endif -%}
  {%- do return(value) -%}
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

{% macro procedure_arguments(arguments) -%}
  {%- if arguments is none -%}
  {%- elif arguments is string -%}
    {{ arguments }}
  {%- elif arguments is sequence -%}
    {%- for argument in arguments -%}
      {%- if argument is mapping -%}
        {{ argument.get('name') }}{% if argument.get('mode') %} {{ argument.get('mode') }}{% endif %} {{ argument.get('data_type', argument.get('type')) }}{% if argument.get('default') is not none %} default {{ argument.get('default') }}{% endif %}
      {%- else -%}
        {{ argument }}
      {%- endif -%}
      {{ ", " if not loop.last }}
    {%- endfor -%}
  {%- else -%}
    {{ exceptions.raise_compiler_error("`arguments` must be a string or a list.") }}
  {%- endif -%}
{%- endmacro %}

{% macro sql_string_list(values) -%}
  {%- for value in values -%}
    {{ sf_ai.sql_string(value) }}{{ ", " if not loop.last }}
  {%- endfor -%}
{%- endmacro %}

{% macro identifier_list(values) -%}
  {%- for value in values -%}
    {{ value }}{{ ", " if not loop.last }}
  {%- endfor -%}
{%- endmacro %}

{% macro secrets_clause(secrets) -%}
  {%- if secrets is mapping and secrets | length > 0 -%}
    secrets = (
      {%- for secret_variable_name, secret_name in secrets.items() -%}
        {{ sf_ai.sql_string(secret_variable_name) }} = {{ secret_name }}{{ ", " if not loop.last }}
      {%- endfor -%}
    )
  {%- endif -%}
{%- endmacro %}
