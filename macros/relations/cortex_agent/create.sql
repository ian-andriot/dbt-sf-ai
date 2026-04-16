{% macro snowflake__get_create_cortex_agent_sql(relation, sql, or_replace=none, if_not_exists=none, comment=none, profile=none) -%}
  {%- set or_replace = config.get('or_replace', default=true) if or_replace is none else or_replace -%}
  {%- set if_not_exists = config.get('if_not_exists', default=false) if if_not_exists is none else if_not_exists -%}
  {%- set comment = config.get('comment', default=none) if comment is none else comment -%}
  {%- set profile = config.get('profile', default=none) if profile is none else profile -%}

  create {{ sf_ai.create_modifier(or_replace, if_not_exists) }} agent {{ sf_ai.if_not_exists_clause(if_not_exists) }} {{ relation }}
  {{ sf_ai.comment_clause(comment) }}
  {{ sf_ai.profile_clause(profile) }}
  from specification
  $$
  {{ sql | trim }}
  $$;
{%- endmacro %}
