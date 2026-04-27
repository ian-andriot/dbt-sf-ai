{{
  config(
    enabled=var('sf_ai_enable_cortex_search_integration_tests', false),
    materialized='cortex_search_service',
    search_column='TEXT',
    primary_key=['DOC_ID'],
    attributes=['CATEGORY'],
    target_lag='1 day',
    initialize='ON_CREATE'
  )
}}

select
  doc_id,
  text,
  category
from {{ ref('cortex_search_documents') }}
