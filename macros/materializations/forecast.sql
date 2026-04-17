{% materialization forecast, adapter='snowflake' -%}
  {%- set original_query_tag = set_query_tag() -%}
  {%- set target_relation = api.Relation.create(identifier=model['alias'], schema=schema, database=database, type='view') -%}
  {%- set timestamp_colname = config.get('timestamp_colname', default=none) -%}
  {%- set target_colname = config.get('target_colname', default=none) -%}
  {%- set series_colname = config.get('series_colname', default=none) -%}
  {%- set config_object = config.get('config_object', default=none) -%}
  {%- set input_data = sf_ai.input_data(sql, config.get('input_data', default=none)) -%}
  {%- set object_tags = config.get('object_tags', default={}) -%}
  {%- set comment = config.get('comment', default=none) -%}

  {%- if timestamp_colname is none or timestamp_colname == '' -%}
    {{ exceptions.raise_compiler_error("Missing required config `timestamp_colname`.") }}
  {%- endif -%}
  {%- if target_colname is none or target_colname == '' -%}
    {{ exceptions.raise_compiler_error("Missing required config `target_colname`.") }}
  {%- endif -%}

  {{ run_hooks(pre_hooks) }}

  {% call statement('main') -%}
    create or replace snowflake.ml.forecast {{ target_relation }}(
      input_data => {{ input_data }},
      {%- if series_colname is not none and series_colname != '' %}
      series_colname => {{ sf_ai.sql_string(series_colname) }},
      {%- endif %}
      timestamp_colname => {{ sf_ai.sql_string(timestamp_colname) }},
      target_colname => {{ sf_ai.sql_string(target_colname) }}
      {%- if config_object is not none and config_object != '' %},
      config_object => {{ config_object }}
      {%- endif %}
    )
    {{ sf_ai.tag_clause(object_tags) }}
    {{ sf_ai.comment_clause(comment) }};
  {%- endcall %}

  {{ run_hooks(post_hooks) }}

  {%- do unset_query_tag(original_query_tag) -%}
  {%- do return({'relations': [target_relation]}) -%}
{%- endmaterialization %}
