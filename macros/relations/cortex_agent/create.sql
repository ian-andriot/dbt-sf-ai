{% macro sf_ai__get_create_cortex_agent_sql(relation, sql, or_replace=none, if_not_exists=none, comment=none, profile=none) -%}
  {%- set or_replace = config.get('or_replace', default=true) if or_replace is none else or_replace -%}
  {%- set if_not_exists = config.get('if_not_exists', default=false) if if_not_exists is none else if_not_exists -%}
  {%- set comment = config.get('comment', default=none) if comment is none else comment -%}
  {%- set profile = config.get('profile', default=none) if profile is none else profile -%}

  create {{ sf_ai.sf_ai__create_modifier(or_replace, if_not_exists) }} agent {{ sf_ai.sf_ai__if_not_exists(if_not_exists) }} {{ relation }}
  {{ sf_ai.sf_ai__comment_clause(comment) }}
  {{ sf_ai.sf_ai__profile_clause(profile) }}
  from specification
  $$
  {{ sql | trim }}
  $$;
{%- endmacro %}
