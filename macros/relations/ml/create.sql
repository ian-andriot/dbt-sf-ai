{% macro snowflake__get_create_forecast_sql(relation, sql, input_data=none, timestamp_colname=none, target_colname=none, series_colname=none, config_object=none, or_replace=none, if_not_exists=none, object_tags=none, comment=none) -%}
  {%- set timestamp_colname = config.get('timestamp_colname', default=none) if timestamp_colname is none else timestamp_colname -%}
  {%- set target_colname = config.get('target_colname', default=none) if target_colname is none else target_colname -%}
  {%- set series_colname = config.get('series_colname', default=none) if series_colname is none else series_colname -%}
  {%- set config_object = config.get('config_object', default=none) if config_object is none else config_object -%}
  {%- set input_data = sf_ai.input_data(sql, config.get('input_data', default=none) if input_data is none else input_data) -%}
  {%- set or_replace = config.get('or_replace', default=true) if or_replace is none else or_replace -%}
  {%- set if_not_exists = config.get('if_not_exists', default=false) if if_not_exists is none else if_not_exists -%}
  {%- set object_tags = config.get('object_tags', default={}) if object_tags is none else object_tags -%}
  {%- set comment = config.get('comment', default=none) if comment is none else comment -%}

  {{ sf_ai.require_config('timestamp_colname', timestamp_colname) }}
  {{ sf_ai.require_config('target_colname', target_colname) }}

  create {{ sf_ai.create_modifier(or_replace, if_not_exists) }} snowflake.ml.forecast {{ sf_ai.if_not_exists_clause(if_not_exists) }} {{ relation }}(
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
{%- endmacro %}

{% macro snowflake__get_create_anomaly_detection_sql(relation, sql, input_data=none, timestamp_colname=none, target_colname=none, label_colname=none, series_colname=none, config_object=none, or_replace=none, object_tags=none, comment=none) -%}
  {%- set timestamp_colname = config.get('timestamp_colname', default=none) if timestamp_colname is none else timestamp_colname -%}
  {%- set target_colname = config.get('target_colname', default=none) if target_colname is none else target_colname -%}
  {%- set label_colname = config.get('label_colname', default=none) if label_colname is none else label_colname -%}
  {%- set series_colname = config.get('series_colname', default=none) if series_colname is none else series_colname -%}
  {%- set config_object = config.get('config_object', default=none) if config_object is none else config_object -%}
  {%- set input_data = sf_ai.input_data(sql, config.get('input_data', default=none) if input_data is none else input_data) -%}
  {%- set or_replace = config.get('or_replace', default=true) if or_replace is none else or_replace -%}
  {%- set object_tags = config.get('object_tags', default={}) if object_tags is none else object_tags -%}
  {%- set comment = config.get('comment', default=none) if comment is none else comment -%}

  {{ sf_ai.require_config('timestamp_colname', timestamp_colname) }}
  {{ sf_ai.require_config('target_colname', target_colname) }}
  {{ sf_ai.require_config('label_colname', label_colname) }}

  create {{ sf_ai.create_modifier(or_replace, false) }} snowflake.ml.anomaly_detection {{ relation }}(
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
{%- endmacro %}

{% macro snowflake__get_create_classification_sql(relation, sql, input_data=none, target_colname=none, config_object=none, or_replace=none, if_not_exists=none, object_tags=none, comment=none) -%}
  {%- set target_colname = config.get('target_colname', default=none) if target_colname is none else target_colname -%}
  {%- set config_object = config.get('config_object', default=none) if config_object is none else config_object -%}
  {%- set input_data = sf_ai.input_data(sql, config.get('input_data', default=none) if input_data is none else input_data) -%}
  {%- set or_replace = config.get('or_replace', default=true) if or_replace is none else or_replace -%}
  {%- set if_not_exists = config.get('if_not_exists', default=false) if if_not_exists is none else if_not_exists -%}
  {%- set object_tags = config.get('object_tags', default={}) if object_tags is none else object_tags -%}
  {%- set comment = config.get('comment', default=none) if comment is none else comment -%}

  {{ sf_ai.require_config('target_colname', target_colname) }}

  create {{ sf_ai.create_modifier(or_replace, if_not_exists) }} snowflake.ml.classification {{ sf_ai.if_not_exists_clause(if_not_exists) }} {{ relation }}(
    input_data => {{ input_data }},
    target_colname => {{ sf_ai.sql_string(target_colname) }}
    {%- if config_object is not none and config_object != '' %},
    config_object => {{ config_object }}
    {%- endif %}
  )
  {{ sf_ai.tag_clause(object_tags) }}
  {{ sf_ai.comment_clause(comment) }};
{%- endmacro %}
