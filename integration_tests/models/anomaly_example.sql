{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='anomaly',
    timestamp_colname='ORDER_TS',
    target_colname='REVENUE',
    label_colname='',
    config_object="OBJECT_CONSTRUCT('evaluate', true)",
    comment='sf-ai integration test anomaly detector'
  )
}}

TABLE({{ ref('base_table') }})
