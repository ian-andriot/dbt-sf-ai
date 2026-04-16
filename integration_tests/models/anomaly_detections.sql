{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='table'
  )
}}

select *
from table(
  {{ ref('anomaly_example') }}!detect_anomalies(
    input_data => table({{ ref('base_table') }}),
    timestamp_colname => 'ORDER_TS',
    target_colname => 'REVENUE',
    series_colname => 'REGION',
    config_object => object_construct('prediction_interval', 0.95, 'on_error', 'skip')
  )
)
