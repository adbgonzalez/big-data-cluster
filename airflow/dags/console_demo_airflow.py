from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator


def create_message() -> str:
    message = "Mensaxe xerada na primeira task."
    print(message)
    return message


def show_received_message(ti) -> None:
    message = ti.xcom_pull(task_ids="first_task")
    print(f"Mensaxe recibida desde XCom: {message}")


with DAG(
    dag_id="console_demo_airflow",
    description="DAG simple con duas tasks que comparten unha mensaxe por XCom.",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo", "xcom"],
) as dag:
    first_task = PythonOperator(
        task_id="first_task",
        python_callable=create_message,
    )

    second_task = PythonOperator(
        task_id="second_task",
        python_callable=show_received_message,
    )

    first_task >> second_task
