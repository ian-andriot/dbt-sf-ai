{{
  config(
    enabled=var('sf_ai_enable_cortex_skill_integration_tests', false),
    materialized='cortex_skill'
  )
}}

name: RefundPolicy
description: Answers questions about refund windows from a dbt-managed Cortex Agent skill.

# Instructions

Use this skill when the user asks about refund windows or refund eligibility.

Gold members have a 45 day refund window. Standard members have a 30 day refund window.
