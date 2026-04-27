{% materialization anomaly, adapter='snowflake' -%}
  {%- set original_query_tag = set_query_tag() -%}
  {%- set target_relation = api.Relation.create(identifier=model['alias'], schema=schema, database=database, type='view') -%}
  {%- set timestamp_colname = config.require('timestamp_colname') -%}
  {%- set target_colname = config.require('target_colname') -%}
  {%- set label_colname = config.get('label_colname', default=none) -%}
  {%- set series_colname = config.get('series_colname', default=none) -%}
  {%- set config_object = config.get('config_object', default=none) -%}
  {%- set input_data = sf_ai.input_data(sql, config.get('input_data', default=none)) -%}
  {%- set object_tags = config.get('object_tags', default={}) -%}
  {%- set comment = sf_ai.object_comment(config.get('comment', default=none)) -%}

  {%- if label_colname is none -%}
    {{ exceptions.raise_compiler_error("Missing required config `label_colname`. Pass an empty string if the training data is unlabeled.") }}
  {%- endif -%}

  {{ run_hooks(pre_hooks) }}

  {% call statement('main') -%}
    create or replace snowflake.ml.anomaly_detection {{ target_relation }}(
      input_data => {{ input_data }},
      {%- if series_colname is not none and series_colname != '' %}
      series_colname => {{ sf_ai.sql_string(series_colname) }},
      {%- endif %}
      timestamp_colname => {{ sf_ai.sql_string(timestamp_colname) }},
      target_colname => {{ sf_ai.sql_string(target_colname) }},
      label_colname => {{ sf_ai.sql_string(label_colname) }}
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
