{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='view'
  )
}}

select
  id,
  order_ts,
  region,
  revenue,
  is_anomaly,
  churned
from {{ ref('base_table') }}

union all

select
  10001 as id,
  dateadd(day, 1, max(order_ts)) as order_ts,
  'NORTH' as region,
  10000::float as revenue,
  true as is_anomaly,
  true as churned
from {{ ref('base_table') }}
