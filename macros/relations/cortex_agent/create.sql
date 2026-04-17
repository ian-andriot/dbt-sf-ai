{% macro snowflake__get_create_cortex_agent_sql(relation, sql, comment=none, profile=none) -%}
  {%- set comment = config.get('comment', default=none) if comment is none else comment -%}
  {%- set profile = config.get('profile', default=none) if profile is none else profile -%}

  create or replace agent {{ relation }}
  {{ sf_ai.comment_clause(comment) }}
  {{ sf_ai.profile_clause(profile) }}
  from specification
$$
{{ sql | trim }}
$$;
{%- endmacro %}
