{{ config(materialized='table') }}

with generated as (
  select
    row_number() over (order by seq4()) as id
  from table(generator(rowcount => 120))
),
features as (
  select
    id,
    dateadd(day, id - 1, '2026-01-01'::timestamp_ntz) as order_ts,
    iff(mod(id, 2) = 0, 'NORTH', 'SOUTH') as region,
    iff(mod(id, 37) = 0, true, false) as is_anomaly,
    100
      + (id * 1.5)
      + iff(mod(id, 2) = 0, 25, -10)
      + iff(mod(id, 37) = 0, 180, 0) as revenue
  from generated
)

select
  id,
  order_ts,
  region,
  revenue::float as revenue,
  is_anomaly,
  (revenue > 210 or is_anomaly) as churned
from features
