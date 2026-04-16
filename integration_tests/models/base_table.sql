{{ config(materialized='table') }}

select
  id,
  order_date::timestamp_ntz as order_ts,
  region,
  revenue::float as revenue,
  is_anomaly::boolean as is_anomaly,
  churned::boolean as churned
from {{ ref('my_seed') }}
