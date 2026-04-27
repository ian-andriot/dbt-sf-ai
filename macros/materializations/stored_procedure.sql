{% materialization stored_procedure, adapter='snowflake', supported_languages=['sql', 'python'] -%}
  {%- set language = model.get('language', 'sql') -%}
  {%- set original_query_tag = set_query_tag() -%}
  {%- set target_relation = api.Relation.create(identifier=model['alias'], schema=schema, database=database, type='view') -%}
  {%- set arguments = config.get('arguments', default=[]) -%}
  {%- set returns = config.require('returns') -%}
  {%- set copy_grants = config.get('copy_grants', default=false) -%}
  {%- set secure = config.get('secure', default=false) -%}
  {%- set temporary = config.get('temporary', default=false) -%}
  {%- set null_input_behavior = config.get('null_input_behavior', default=none) -%}
  {%- set volatility = config.get('volatility', default=none) -%}
  {%- set execute_as = config.get('execute_as', default=none) -%}
  {%- set comment = sf_ai.object_comment(config.get('comment', default=none)) -%}

  {%- set python_version = config.get('python_version', default='3.10') -%}
  {%- set packages = config.get('packages', default=['snowflake-snowpark-python']) -%}
  {%- set imports = config.get('imports', default=[]) -%}
  {%- set external_access_integrations = config.get('external_access_integrations', default=[]) -%}
  {%- set secrets = config.get('secrets', default={}) -%}
  {%- set artifact_repository = config.get('artifact_repository', default=none) -%}

  {{ run_hooks(pre_hooks) }}

  {% call statement('main') -%}
    create or replace
    {%- if temporary %} temporary{% endif %}
    {%- if secure %} secure{% endif %}
    procedure {{ target_relation }}({{ sf_ai.procedure_arguments(arguments) }})
    {%- if copy_grants %} copy grants{% endif %}
    returns {{ returns }}
    language {{ language }}
    {%- if language == 'python' %}
    runtime_version = {{ sf_ai.sql_string(python_version) }}
      {%- if artifact_repository is not none and artifact_repository != '' %}
    artifact_repository = {{ artifact_repository }}
      {%- endif %}
      {%- if packages is sequence and packages is not string and packages | length > 0 %}
    packages = ({{ sf_ai.sql_string_list(packages) }})
      {%- endif %}
      {%- if imports is sequence and imports is not string and imports | length > 0 %}
    imports = ({{ sf_ai.sql_string_list(imports) }})
      {%- endif %}
    handler = '_sf_ai_main'
      {%- if external_access_integrations is sequence and external_access_integrations is not string and external_access_integrations | length > 0 %}
    external_access_integrations = ({{ sf_ai.identifier_list(external_access_integrations) }})
      {%- endif %}
    {{ sf_ai.secrets_clause(secrets) }}
    {%- endif %}
    {%- if null_input_behavior is not none and null_input_behavior != '' %}
    {{ null_input_behavior }}
    {%- endif %}
    {%- if volatility is not none and volatility != '' %}
    {{ volatility }}
    {%- endif %}
    {{ sf_ai.comment_clause(comment) }}
    {%- if execute_as is not none and execute_as != '' %}
    execute as {{ execute_as }}
    {%- endif %}
    as
$$
{%- if language == 'python' %}
{{ compiled_code }}


def _sf_ai_main(session, *args):
    dbt = dbtObj(session.table)
    result = model(dbt, session)
    if callable(result):
        return result(*args)
    return result
{%- else %}
{{ sql | trim }}
{%- endif %}
$$;
  {%- endcall %}

  {{ run_hooks(post_hooks) }}

  {%- do unset_query_tag(original_query_tag) -%}
  {%- do return({'relations': [target_relation]}) -%}
{%- endmaterialization %}
