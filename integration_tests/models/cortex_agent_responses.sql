{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='table'
  )
}}

select
  '{{ ref('cortex_agent_example') }}' as agent_name,
  'What is total revenue by region?' as question,
  try_parse_json(
    snowflake.cortex.data_agent_run(
      '{{ ref('cortex_agent_example') }}',
      $${
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "What is total revenue by region?"
              }
            ]
          }
        ],
        "tool_choice": {
          "type": "auto",
          "name": ["OrdersAnalyst"]
        }
      }$$
    )
  ) as response
