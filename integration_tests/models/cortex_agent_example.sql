{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='cortex_agent',
    comment='sf-ai integration test agent',
    profile={"display_name": "sf-ai test agent", "color": "blue"}
  )
}}

instructions:
  system: "You are a dbt integration test agent."
  response: "Answer briefly and include the phrase sf-ai integration ok when asked for a health check."
  sample_questions:
    - question: "Run the health check."
      answer: "sf-ai integration ok"
