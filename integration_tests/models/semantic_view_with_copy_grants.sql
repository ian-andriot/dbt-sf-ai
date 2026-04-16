{{
  config(
    materialized='semantic_view',
    copy_grants=true
  )
}}

tables (
  ORDERS as {{ ref('base_table') }} primary key (ID)
)
facts (
  ORDERS.REVENUE as REVENUE
)
dimensions (
  ORDERS.REGION as REGION
)
metrics (
  ORDERS.TOTAL_REVENUE as sum(REVENUE)
)
comment = 'copy grants semantic view'
