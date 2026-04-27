{{
  config(
    enabled=var('sf_ai_enable_cortex_search_integration_tests', false),
    materialized='cortex_agent',
    comment='sf-ai integration test agent with cortex search',
    profile={"display_name": "sf-ai search agent", "color": "green"}
  )
}}

models:
  orchestration: claude-4-sonnet
instructions:
  system: "You are a dbt integration test agent."
  orchestration: "Use the search tool for policy and refund questions."
  response: "Answer briefly and cite the policy detail from the search results."
tools:
  - tool_spec:
      type: "cortex_search"
      name: "PolicySearch"
      description: "Searches refund and support policy documents."
tool_resources:
  PolicySearch:
    name: "{{ ref('cortex_search_service_example') }}"
    max_results: 3
    title_column: "DOC_ID"
    id_column: "DOC_ID"
    columns_and_descriptions:
      TEXT:
        description: "Policy text. Search this column for the answer wording."
        type: "string"
        searchable: true
        filterable: false
      CATEGORY:
        description: "Policy category such as refund or support."
        type: "string"
        searchable: false
        filterable: true
