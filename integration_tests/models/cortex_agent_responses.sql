{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='table'
  )
}}

select
  '{{ ref('cortex_agent_example') }}' as agent_name,
  'Run the health check.' as question,
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
                "text": "Run the health check."
              }
            ]
          }
        ]
      }$$
    )
  ) as response
