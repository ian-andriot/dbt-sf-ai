{{
  config(
    enabled=var('sf_ai_enable_ai_integration_tests', false),
    materialized='test'
  )
}}

select 'anomaly_detections was not materialized' as error_message
where not exists (
  select 1
  from {{ ref('anomaly_detections') }}
  where 1 = 0
)
  and not exists (
    select 1
    from information_schema.tables
    where upper(table_schema) = upper('{{ target.schema }}')
      and upper(table_name) = 'ANOMALY_DETECTIONS'
  )
