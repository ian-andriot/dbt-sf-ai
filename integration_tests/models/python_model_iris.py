def model(dbt, session):
    dbt.config(
        materialized="python_model",
        packages=["snowflake-ml-python", "scikit-learn", "pandas"],
        model_name="SF_AI_IRIS_CLASSIFIER",
        aliases=["dev"],
        set_default=True,
        metrics={"dataset": "iris"},
        comment="sf-ai integration test Iris classifier",
    )

    import pandas as pd
    from sklearn.datasets import load_iris
    from sklearn.ensemble import RandomForestClassifier

    iris = load_iris()
    feature_names = [
        "SEPAL_LENGTH",
        "SEPAL_WIDTH",
        "PETAL_LENGTH",
        "PETAL_WIDTH",
    ]
    x_train = pd.DataFrame(iris.data, columns=feature_names)
    y_train = pd.Series(iris.target, name="SPECIES")

    classifier = RandomForestClassifier(n_estimators=20, random_state=7)
    classifier.fit(x_train, y_train)

    return {
        "model": classifier,
        "sample_input_data": x_train.head(5),
        "metrics": {"training_rows": len(x_train), "classes": len(iris.target_names)},
        "metadata": {"dataset": "iris"},
    }
