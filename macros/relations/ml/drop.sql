{% macro sf_ai__get_drop_forecast_sql(relation) -%}
  drop snowflake.ml.forecast if exists {{ relation }}
{%- endmacro %}

{% macro sf_ai__get_drop_anomaly_detection_sql(relation) -%}
  drop snowflake.ml.anomaly_detection if exists {{ relation }}
{%- endmacro %}

{% macro sf_ai__get_drop_classification_sql(relation) -%}
  drop snowflake.ml.classification if exists {{ relation }}
{%- endmacro %}
