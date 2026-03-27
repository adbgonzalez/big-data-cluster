from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator


def say_hello() -> None:
    print("Airflow DAG de proba executado correctamente.")


with DAG(
    dag_id="hello_airflow",
    description="DAG minimo para comprobar que Airflow esta operativo.",
    start_date=datetime(2026, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["demo", "sanity-check"],
) as dag:
    start = EmptyOperator(task_id="start")

    hello = PythonOperator(
        task_id="say_hello",
        python_callable=say_hello,
    )

    end = EmptyOperator(task_id="end")

    start >> hello >> end