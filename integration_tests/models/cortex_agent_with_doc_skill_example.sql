{{
  config(
    enabled=var('sf_ai_enable_cortex_skill_integration_tests', false),
    materialized='cortex_agent',
    profile={"display_name": "sf-ai skill agent", "color": "green"}
  )
}}

models:
  orchestration: claude-4-sonnet
instructions:
  system: "You are a dbt integration test agent."
  orchestration: "Use the RefundPolicy skill for refund questions."
  response: "Answer briefly using the relevant skill."
skills:
  - name: RefundPolicy
    source:
      type: STAGE
      path: "@{{ ref('refund_policy_skill') }}"
