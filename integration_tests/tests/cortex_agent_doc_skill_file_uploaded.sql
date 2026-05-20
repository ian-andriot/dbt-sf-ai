{{
  config(
    enabled=var('sf_ai_enable_cortex_skill_integration_tests', false),
    severity='error'
  )
}}

select 'managed skill file was not uploaded' as error_message
where not exists (
  select 1
  from {{ ref('cortex_agent_doc_skill_stage_files') }}
  where relative_path = 'SKILL.md'
)
