{{
  config(
    enabled=var('sf_ai_enable_procedure_integration_tests', false),
    materialized='cortex_agent',
    profile={"display_name": "sf-ai procedure agent", "color": "purple"}
  )
}}

models:
  orchestration: claude-4-sonnet
instructions:
  system: "You are a dbt integration test agent."
  orchestration: "Use SQLGreeting for SQL procedure questions and PythonGreeting for Python procedure questions."
  response: "Answer briefly with the greeting returned by the selected tool."
tools:
  - tool_spec:
      type: "generic"
      name: "SQLGreeting"
      description: "Calls a SQL stored procedure that returns a greeting table."
      input_schema:
        type: "object"
        properties:
          name:
            type: "string"
            description: "Name to greet."
        required:
          - name
  - tool_spec:
      type: "generic"
      name: "PythonGreeting"
      description: "Calls a Python stored procedure that returns a greeting table."
      input_schema:
        type: "object"
        properties:
          name:
            type: "string"
            description: "Name to greet."
        required:
          - name
tool_resources:
  SQLGreeting:
    type: "procedure"
    identifier: "{{ ref('sql_stored_procedure_example') }}"
    execution_environment:
      type: "warehouse"
      warehouse: "{{ target.warehouse }}"
      query_timeout: 60
  PythonGreeting:
    type: "procedure"
    identifier: "{{ ref('python_stored_procedure_example') }}"
    execution_environment:
      type: "warehouse"
      warehouse: "{{ target.warehouse }}"
      query_timeout: 60
