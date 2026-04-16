{{ config(materialized='semantic_view') }}

tables (
  ORDERS as {{ ref('base_table') }} primary key (ID)
)
facts (
  ORDERS.REVENUE as REVENUE
)
dimensions (
  ORDERS.ID as ORDER_ID,
  ORDERS.ORDER_TS as ORDER_TS,
  ORDERS.REGION as REGION
)
metrics (
  ORDERS.TOTAL_REVENUE as sum(REVENUE),
  ORDERS.ORDER_COUNT as count(ID)
)
comment = 'test semantic view'
