{{
  config(
    enabled=var('sf_ai_enable_cortex_search_integration_tests', false),
    materialized='test'
  )
}}

select 'cortex agent search response missing expected policy detail' as error_message
from {{ ref('cortex_agent_search_responses') }}
where response is null
  or not regexp_like(lower(to_varchar(response)), 'gold')
  or not regexp_like(lower(to_varchar(response)), '30|thirty')
limit 1
