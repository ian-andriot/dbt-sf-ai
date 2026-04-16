{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='classification',
    target_colname='CHURNED',
    config_object="OBJECT_CONSTRUCT('evaluate', true)",
    comment='sf-ai integration test classifier'
  )
}}

TABLE({{ ref('base_table') }})
