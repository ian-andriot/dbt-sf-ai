{% materialization cortex_search_service, adapter='snowflake' -%}
  {%- set original_query_tag = set_query_tag() -%}
  {%- set target_relation = api.Relation.create(identifier=model['alias'], schema=schema, database=database, type='view') -%}
  {%- set search_column = config.require('search_column') -%}
  {%- set primary_key = config.get('primary_key', default=[]) -%}
  {%- set attributes = config.get('attributes', default=[]) -%}
  {%- set warehouse = config.get('warehouse', default=target.warehouse) -%}
  {%- set target_lag = config.get('target_lag', default='1 day') -%}
  {%- set embedding_model = config.get('embedding_model', default=none) -%}
  {%- set refresh_mode = config.get('refresh_mode', default=none) -%}
  {%- set initialize = config.get('initialize', default='ON_CREATE') -%}
  {%- set full_index_build_interval_days = config.get('full_index_build_interval_days', default=none) -%}
  {%- set request_logging = config.get('request_logging', default=none) -%}
  {%- set comment = sf_ai.object_comment(config.get('comment', default=none)) -%}

  {%- do sf_ai.config_require_non_empty_list("attributes", attributes) -%}
  {%- if warehouse is none or warehouse == "" -%}
    {{ exceptions.raise_compiler_error("Missing required config `warehouse`, and no target warehouse was available.") }}
  {%- endif -%}

  {{ run_hooks(pre_hooks) }}

  {% call statement('main') -%}
    create or replace cortex search service {{ target_relation }}
      on {{ search_column }}
      {%- if primary_key is sequence and primary_key is not string and primary_key | length > 0 %}
      primary key ({{ primary_key | join(', ') }})
      {%- endif %}
      attributes {{ attributes | join(', ') }}
      warehouse = {{ warehouse }}
      target_lag = {{ sf_ai.sql_string(target_lag) }}
      {%- if embedding_model is not none and embedding_model != '' %}
      embedding_model = {{ sf_ai.sql_string(embedding_model) }}
      {%- endif %}
      {%- if refresh_mode is not none and refresh_mode != '' %}
      refresh_mode = {{ refresh_mode }}
      {%- endif %}
      {%- if initialize is not none and initialize != '' %}
      initialize = {{ initialize }}
      {%- endif %}
      {%- if full_index_build_interval_days is not none %}
      full_index_build_interval_days = {{ full_index_build_interval_days }}
      {%- endif %}
      {%- if request_logging is not none %}
      request_logging = {{ 'TRUE' if request_logging else 'FALSE' }}
      {%- endif %}
      {{ sf_ai.comment_clause(comment) }}
    as
{{ sql | trim }};
  {%- endcall %}

  {{ run_hooks(post_hooks) }}

  {%- do unset_query_tag(original_query_tag) -%}
  {%- do return({'relations': [target_relation]}) -%}
{%- endmaterialization %}
