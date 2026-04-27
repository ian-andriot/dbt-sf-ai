{{
  config(
    enabled=var('sf_ai_enable_cortex_search_integration_tests', false),
    materialized='table'
  )
}}

select
  'refund_gold' as doc_id,
  'Gold members receive a 30 day refund window for annual plans.' as text,
  'refund' as category
union all
select
  'refund_silver' as doc_id,
  'Silver members receive a 14 day refund window for annual plans.' as text,
  'refund' as category
union all
select
  'support_hours' as doc_id,
  'Support is available Monday through Friday from 9 AM to 5 PM Eastern.' as text,
  'support' as category
