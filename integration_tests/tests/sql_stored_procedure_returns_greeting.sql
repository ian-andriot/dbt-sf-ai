{{
  config(
    enabled=var('sf_ai_enable_procedure_integration_tests', false),
    severity='error'
  )
}}

select 1 as failure
where not exists (
  select 1
  from {{ ref('sql_stored_procedure_results') }}
  where greeting = 'hello sql'
)
