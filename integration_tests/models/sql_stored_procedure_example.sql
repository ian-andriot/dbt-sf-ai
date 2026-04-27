{{
  config(
    enabled=var('sf_ai_enable_procedure_integration_tests', false),
    materialized='stored_procedure',
    arguments=['NAME STRING'],
    returns='TABLE (GREETING STRING)',
    execute_as='CALLER'
  )
}}

DECLARE
  res RESULTSET;
BEGIN
  res := (select 'hello ' || :NAME as greeting);
  RETURN TABLE(res);
END
