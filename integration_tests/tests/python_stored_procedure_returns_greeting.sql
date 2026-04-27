{{
  config(
    enabled=var('sf_ai_enable_procedure_integration_tests', false),
    severity='error'
  )
}}

select 1 as failure
where not exists (
  select 1
  from {{ ref('python_stored_procedure_results') }}
  where greeting = 'hello python'
    and package_check = 'pandas'
)
