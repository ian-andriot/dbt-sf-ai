{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='table'
  )
}}

select *
from table(
  {{ ref('anomaly_example') }}!detect_anomalies(
    input_data => table({{ ref('anomaly_scoring_data') }}),
    timestamp_colname => 'ORDER_TS',
    target_colname => 'REVENUE',
    config_object => object_construct('prediction_interval', 0.01, 'on_error', 'skip')
  )
)
