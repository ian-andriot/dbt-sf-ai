{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='test'
  )
}}

select 'cortex agent response missing payload' as error_message
from {{ ref('cortex_agent_responses') }}
where response is null
  or (response:content is null and response:code is null)
limit 1
