{% materialization python_model, adapter='snowflake', supported_languages=['python'] -%}
  {%- if flags.FULL_REFRESH -%}
    {{ exceptions.raise_compiler_error("python_model is append-only and does not support --full-refresh.") }}
  {%- endif -%}

  {%- set original_query_tag = set_query_tag() -%}
  {%- set history_relation = api.Relation.create(identifier=model['alias'], schema=schema, database=database, type='table') -%}
  {%- set registry_database = config.get('registry_database', default=database) -%}
  {%- set registry_schema = config.get('registry_schema', default=schema) -%}
  {%- set default_model_name = (model['fqn'] | join('__') | replace('-', '_') | upper) -%}
  {%- set model_name = config.get('model_name', default=default_model_name) -%}
  {%- set version_name = config.get('version_name', default=none) -%}
  {%- set aliases = config.get('aliases', default=[]) -%}
  {%- set metrics = config.get('metrics', default={}) -%}
  {%- set registry_tags = config.get('registry_tags', default={}) -%}
  {%- set comment = config.get('comment', default=none) -%}
  {%- set set_default = config.get('set_default', default=false) -%}
  {%- set registry_options = config.get('registry_options', default=none) -%}
  {%- set log_model_options = config.get('log_model_options', default=none) -%}
  {%- set conda_dependencies = config.get('conda_dependencies', default=none) -%}
  {%- set pip_requirements = config.get('pip_requirements', default=none) -%}
  {%- set target_platforms = config.get('target_platforms', default=none) -%}
  {%- set resource_constraint = config.get('resource_constraint', default=none) -%}
  {%- set artifact_repository_map = config.get('artifact_repository_map', default=none) -%}

  {{ run_hooks(pre_hooks) }}

  {% call statement('create_history_table') -%}
    create table if not exists {{ history_relation }} (
      model_name string,
      version_name string,
      registered_at timestamp_ntz,
      dbt_invocation_id string,
      dbt_model_unique_id string,
      dbt_model_fqn string,
      registry_database string,
      registry_schema string,
      registry_name string,
      aliases variant,
      metrics variant,
      registry_tags variant,
      comment string,
      status string,
      error_message string,
      registry_metadata variant
    )
  {%- endcall %}

  {% call statement('main', language='python') -%}
{{ compiled_code }}

import json
import traceback
from datetime import datetime
from typing import Any, Optional

_CONFIG = json.loads(r'''
{
    "history_table": {{ (history_relation | string) | tojson }},
    "registry_database": {{ registry_database | tojson }},
    "registry_schema": {{ registry_schema | tojson }},
    "model_name": {{ model_name | tojson }},
    "version_name": {{ version_name | tojson }},
    "aliases": {{ aliases | tojson }},
    "metrics": {{ metrics | tojson }},
    "registry_tags": {{ registry_tags | tojson }},
    "comment": {{ comment | tojson }},
    "set_default": {{ set_default | tojson }},
    "registry_options": {{ registry_options | tojson }},
    "log_model_options": {{ log_model_options | tojson }},
    "conda_dependencies": {{ conda_dependencies | tojson }},
    "pip_requirements": {{ pip_requirements | tojson }},
    "target_platforms": {{ target_platforms | tojson }},
    "resource_constraint": {{ resource_constraint | tojson }},
    "artifact_repository_map": {{ artifact_repository_map | tojson }},
    "dbt_invocation_id": {{ invocation_id | tojson }},
    "dbt_model_unique_id": {{ model['unique_id'] | tojson }},
    "dbt_model_fqn": {{ (model['fqn'] | join('.')) | tojson }}
}
''')


def sql_string(value: Any) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def sql_identifier(value: Any) -> str:
    return "\"" + str(value).replace("\"", "\"\"") + "\""


def json_expr(value: Any) -> str:
    return "try_parse_json(" + sql_string(json.dumps(value, default=str)) + ")"


def history_row(
    session: Any,
    status: str,
    error_message: Optional[str] = None,
    registry_metadata: Optional[dict] = None,
    metrics: Optional[dict] = None,
    model_name: Optional[str] = None,
    version_name: Optional[str] = None,
) -> None:
    model_name = _CONFIG["model_name"] if model_name is None else model_name
    version_name = _CONFIG["version_name"] if version_name is None else version_name
    metrics = _CONFIG["metrics"] if metrics is None else metrics
    registry_metadata = registry_metadata or {}
    registry_name = ".".join([
        _CONFIG["registry_database"],
        _CONFIG["registry_schema"],
        model_name,
    ])
    session.sql(f"""
        insert into {_CONFIG['history_table']} (
          model_name, version_name, registered_at, dbt_invocation_id,
          dbt_model_unique_id, dbt_model_fqn, registry_database,
          registry_schema, registry_name, aliases, metrics, registry_tags,
          comment, status, error_message, registry_metadata
        )
        select
          {sql_string(model_name)},
          {sql_string(version_name)},
          current_timestamp(),
          {sql_string(_CONFIG['dbt_invocation_id'])},
          {sql_string(_CONFIG['dbt_model_unique_id'])},
          {sql_string(_CONFIG['dbt_model_fqn'])},
          {sql_string(_CONFIG['registry_database'])},
          {sql_string(_CONFIG['registry_schema'])},
          {sql_string(registry_name)},
          {json_expr(_CONFIG['aliases'])},
          {json_expr(metrics)},
          {json_expr(_CONFIG['registry_tags'])},
          {sql_string(_CONFIG['comment'])},
          {sql_string(status)},
          {sql_string(error_message)},
          {json_expr(registry_metadata)}
    """).collect()


def payload_from(result: Any) -> dict:
    if isinstance(result, dict) and "model" in result:
        return result
    return {"model": result}


def log_model_kwargs(payload: dict) -> dict:
    kwargs = {}
    config_keys = [
        "conda_dependencies",
        "pip_requirements",
        "target_platforms",
        "resource_constraint",
        "artifact_repository_map",
    ]
    payload_keys = [
        "sample_input_data",
        "signatures",
        "options",
        "conda_dependencies",
        "pip_requirements",
        "target_platforms",
        "resource_constraint",
        "artifact_repository_map",
    ]
    for key in config_keys:
        if _CONFIG.get(key) is not None:
            kwargs[key] = _CONFIG[key]
    if _CONFIG.get("log_model_options") is not None:
        kwargs["options"] = _CONFIG["log_model_options"]
    for key in payload_keys:
        if payload.get(key) is not None:
            kwargs[key] = payload[key]
    return kwargs


def promote(session: Any, model_name: str, version_name: str) -> None:
    model_fqn = ".".join([
        sql_identifier(_CONFIG["registry_database"].upper()),
        sql_identifier(_CONFIG["registry_schema"].upper()),
        sql_identifier(model_name),
    ])
    if _CONFIG["set_default"]:
        session.sql(
            f"alter model if exists {model_fqn} set default_version = {sql_string(version_name)}"
        ).collect()
    for alias in _CONFIG["aliases"]:
        alias_identifier = sql_identifier(str(alias).upper())
        try:
            session.sql(
                f"alter model if exists {model_fqn} version {alias_identifier} unset alias"
            ).collect()
        except Exception:
            pass
        session.sql(
            f"alter model if exists {model_fqn} version {sql_identifier(version_name)} set alias = {alias_identifier}"
        ).collect()
    for tag_name, tag_value in _CONFIG["registry_tags"].items():
        session.sql(
            f"alter model if exists {model_fqn} set tag {tag_name} = {sql_string(tag_value)}"
        ).collect()


def main(session: Any) -> str:
    dbt = dbtObj(session.table)
    try:
        from snowflake.ml.registry import Registry

        payload = payload_from(model(dbt, session))
        model_name = payload.get("model_name", _CONFIG["model_name"])
        version_name = str(
            payload.get("version_name")
            or _CONFIG["version_name"]
            or f"V{datetime.utcnow().strftime('%Y%m%d_%H%M%S_%f')}_UTC"
        ).upper()
        metrics = payload.get("metrics", _CONFIG["metrics"])
        comment = payload.get("comment", _CONFIG["comment"])
        registry = Registry(
            session=session,
            database_name=_CONFIG["registry_database"],
            schema_name=_CONFIG["registry_schema"],
            options=_CONFIG["registry_options"],
        )
        model_version = registry.log_model(
            model=payload["model"],
            model_name=model_name,
            version_name=version_name,
            comment=comment,
            metrics=metrics,
            **log_model_kwargs(payload),
        )
        promote(session, model_name, version_name)
        metadata = payload.get("metadata", {}) or {}
        metadata.update({"model_version": str(model_version)})
        history_row(
            session,
            "success",
            registry_metadata=metadata,
            metrics=metrics,
            model_name=model_name,
            version_name=version_name,
        )
        return "OK"
    except Exception as exc:
        history_row(
            session,
            "error",
            error_message=str(exc),
            registry_metadata={"traceback": traceback.format_exc()},
        )
        raise
  {%- endcall %}

  {{ run_hooks(post_hooks) }}

  {%- do unset_query_tag(original_query_tag) -%}
  {%- do return({'relations': [history_relation]}) -%}
{%- endmaterialization %}
