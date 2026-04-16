{{ config(materialized='table') }}

select *
from semantic_view(
  {{ ref('semantic_view_basic') }}
  metrics total_revenue, order_count
  dimensions region
)
