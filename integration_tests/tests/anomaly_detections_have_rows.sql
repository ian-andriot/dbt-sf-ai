{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='test'
  )
}}

select 'anomaly_detections returned no rows' as error_message
where not exists (
  select 1
  from {{ ref('anomaly_detections') }}
)
