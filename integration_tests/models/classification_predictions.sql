{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='table'
  )
}}

with prediction_input as (
  select
    id,
    order_ts,
    region,
    revenue,
    is_anomaly
  from {{ ref('base_table') }}
)

select
  *,
  {{ ref('classification_example') }}!predict(
    input_data => {*},
    config_object => object_construct('on_error', 'skip')
  ) as prediction
from prediction_input
