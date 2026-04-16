{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='cortex_agent',
    comment='sf-ai integration test agent',
    profile={"display_name": "sf-ai test agent", "color": "blue"}
  )
}}

models:
  orchestration: claude-4-sonnet
instructions:
  response: "Answer briefly and cite the semantic view when relevant."
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "OrdersAnalyst"
      description: "Answers order revenue questions"
tool_resources:
  OrdersAnalyst:
    semantic_view: "{{ ref('semantic_view_basic') }}"
