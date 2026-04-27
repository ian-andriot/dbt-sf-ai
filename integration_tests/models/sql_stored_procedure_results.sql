{{
  config(
    enabled=var('sf_ai_enable_procedure_integration_tests', false),
    materialized='table'
  )
}}

select *
from table({{ ref('sql_stored_procedure_example') }}('sql'))
