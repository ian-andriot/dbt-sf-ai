{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='table'
  )
}}

select
  series,
  ts,
  forecast,
  lower_bound,
  upper_bound
from table(
  {{ ref('forecast_example') }}!forecast(
    forecasting_periods => 2,
    config_object => object_construct('prediction_interval', 0.8, 'on_error', 'skip')
  )
)
