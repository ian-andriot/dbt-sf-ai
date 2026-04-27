{% materialization cortex_agent, adapter='snowflake' -%}
  {%- set original_query_tag = set_query_tag() -%}
  {%- set target_relation = api.Relation.create(identifier=model['alias'], schema=schema, database=database, type='view') -%}
  {%- set comment = sf_ai.object_comment(config.get('comment', default=none)) -%}
  {%- set profile = config.get('profile', default=none) -%}

  {{ run_hooks(pre_hooks) }}

  {% call statement('main') -%}
    create or replace agent {{ target_relation }}
    {{ sf_ai.comment_clause(comment) }}
    {{ sf_ai.profile_clause(profile) }}
    from specification
$$
{{ sql | trim }}
$$;
  {%- endcall %}

  {{ run_hooks(post_hooks) }}

  {%- do unset_query_tag(original_query_tag) -%}
  {%- do return({'relations': [target_relation]}) -%}
{%- endmaterialization %}
