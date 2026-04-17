{{
  config(
    enabled=var('sf_ai_enable_registry_integration_tests', false),
    severity='error'
  )
}}

select 1 as failure
where not exists (
  select 1
  from {{ ref('python_model_iris') }}
  where model_name = 'SF_AI_IRIS_CLASSIFIER'
    and status = 'success'
)
