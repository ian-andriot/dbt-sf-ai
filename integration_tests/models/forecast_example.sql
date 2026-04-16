{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='forecast',
    timestamp_colname='ORDER_TS',
    target_colname='REVENUE',
    series_colname='REGION',
    config_object="OBJECT_CONSTRUCT('method', 'fast')",
    comment='sf-ai integration test forecast'
  )
}}

TABLE({{ ref('forecast_training_data') }})
