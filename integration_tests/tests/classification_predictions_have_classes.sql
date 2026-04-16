{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='test'
  )
}}

select 'classification prediction missing class' as error_message
from {{ ref('classification_predictions') }}
where prediction:class is null
limit 1
