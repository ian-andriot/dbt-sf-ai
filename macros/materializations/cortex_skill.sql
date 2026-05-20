{% materialization cortex_skill, adapter='snowflake' -%}
  {%- set original_query_tag = set_query_tag() -%}
  {%- set target_relation = api.Relation.create(identifier=model['alias'], schema=schema, database=database) -%}
  {%- set skill_writer_relation = api.Relation.create(identifier=model['alias'] ~ '__PUT_SKILL', schema=schema, database=database) -%}
  {%- set skill_body = sql | trim -%}

  {%- if skill_body == '' -%}
    {{ exceptions.raise_compiler_error("cortex_skill models must contain SKILL.md content in the model body.") }}
  {%- endif -%}
  {%- set skill_body_lower = skill_body | lower -%}
  {%- if 'name:' not in skill_body_lower or 'description:' not in skill_body_lower or ('instructions:' not in skill_body_lower and '# instructions' not in skill_body_lower) -%}
    {{ exceptions.raise_compiler_error("cortex_skill models must include Snowflake's required SKILL.md fields: `name`, `description`, and instructions content.") }}
  {%- endif -%}

  {{ run_hooks(pre_hooks) }}

  {% call statement('main') -%}
    create stage if not exists {{ target_relation }}
    directory = (enable = true);
  {%- endcall %}

  {% call statement('enable_skill_stage_directory') -%}
    alter stage {{ target_relation }}
    set directory = (enable = true);
  {%- endcall %}

  {% call statement('create_skill_writer') -%}
    create or replace temporary procedure {{ skill_writer_relation }}(
      stage_path string,
      body string
    )
    returns string
    language python
    runtime_version = '3.10'
    packages = ('snowflake-snowpark-python')
    handler = 'main'
    execute as caller
    as
$$
from io import BytesIO


def main(session, stage_path: str, body: str) -> str:
    session.file.put_stream(
        BytesIO(body.encode("utf-8")),
        stage_path,
        overwrite=True,
        auto_compress=False,
    )
    return stage_path
$$;
  {%- endcall %}

  {% call statement('put_skill') -%}
    call {{ skill_writer_relation }}(
      {{ sf_ai.sql_string('@' ~ target_relation ~ '/SKILL.md') }},
      {{ sf_ai.sql_string(skill_body) }}
    );
  {%- endcall %}

  {% call statement('refresh_skill_stage_directory') -%}
    alter stage {{ target_relation }} refresh;
  {%- endcall %}

  {{ run_hooks(post_hooks) }}

  {%- do unset_query_tag(original_query_tag) -%}
  {%- do return({'relations': [target_relation]}) -%}
{%- endmaterialization %}
