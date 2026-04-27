def model(dbt, session):
    dbt.config(
        materialized="stored_procedure",
        arguments=["NAME STRING"],
        returns="TABLE (GREETING STRING, PACKAGE_CHECK STRING)",
        packages=["snowflake-snowpark-python", "pandas"],
        execute_as="CALLER",
    )

    import pandas as pd

    def run(name):
        package_check = pd.Series(["pandas"]).iloc[0]
        return session.create_dataframe(
            [[f"hello {name}", package_check]],
            schema=["GREETING", "PACKAGE_CHECK"],
        )

    return run
