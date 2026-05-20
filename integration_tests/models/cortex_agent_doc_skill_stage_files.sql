{{
  config(
    enabled=var('sf_ai_enable_cortex_skill_integration_tests', false),
    materialized='table'
  )
}}

-- depends_on: {{ ref('cortex_agent_with_doc_skill_example') }}

select
  relative_path,
  size,
  last_modified
from directory(@{{ ref('refund_policy_skill') }})
