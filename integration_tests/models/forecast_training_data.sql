{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='view'
  )
}}

select
  order_ts,
  region,
  revenue
from {{ ref('base_table') }}
