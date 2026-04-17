{{
  config(
    enabled=var('sf_ai_enable_registry_integration_tests', false),
    materialized='table'
  )
}}

with iris_inference_input as (
  select
    5.1::float as sepal_length,
    3.5::float as sepal_width,
    1.4::float as petal_length,
    0.2::float as petal_width
  union all
  select
    6.7::float as sepal_length,
    3.0::float as sepal_width,
    5.2::float as petal_length,
    2.3::float as petal_width
)

select
  *,
  {{
    sf_ai.registry_model_call(
      ref('python_model_iris'),
      'predict',
      ['sepal_length', 'sepal_width', 'petal_length', 'petal_width'],
      alias='DEV'
    )
  }} as prediction
from iris_inference_input
