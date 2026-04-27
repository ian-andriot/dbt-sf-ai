{{
  config(
    enabled=var('sf_ai_enable_cortex_search_integration_tests', false),
    materialized='table'
  )
}}

select
  '{{ ref('cortex_agent_with_search_example') }}' as agent_name,
  'What is the refund window for gold members?' as question,
  try_parse_json(
    snowflake.cortex.data_agent_run(
      '{{ ref('cortex_agent_with_search_example') }}',
      $$
      {
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "What is the refund window for gold members?"
              }
            ]
          }
        ],
        "tool_choice": {
          "type": "tool",
          "name": ["PolicySearch"]
        }
      }
      $$
    )
  ) as response
