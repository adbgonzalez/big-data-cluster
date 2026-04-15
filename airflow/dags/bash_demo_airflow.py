from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator


with DAG(
    dag_id="bash_demo_airflow",
    description="DAG simple con duas tasks usando BashOperator.",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo", "bash"],
) as dag:
    show_start = BashOperator(
        task_id="show_start",
        bash_command='echo "Inicio do DAG de proba"',
    )

    show_date = BashOperator(
        task_id="show_date",
        bash_command="date",
    )

    show_start >> show_date
