from __future__ import annotations

from datetime import datetime
from pathlib import Path

from airflow import DAG
from airflow.operators.python import PythonOperator


OUTPUT_DIR = Path("/opt/airflow/logs/demo_output")
OUTPUT_FILE = OUTPUT_DIR / "file_demo_output.txt"


def build_text() -> str:
    message = "Este ficheiro foi creado por un DAG de Airflow."
    print(message)
    return message


def write_file(ti) -> None:
    message = ti.xcom_pull(task_ids="build_text")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(f"{message}\n", encoding="utf-8")
    print(f"Ficheiro escrito en: {OUTPUT_FILE}")


with DAG(
    dag_id="file_demo_airflow",
    description="DAG simple que escribe un ficheiro de proba.",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo", "files"],
) as dag:
    build_text_task = PythonOperator(
        task_id="build_text",
        python_callable=build_text,
    )

    write_file_task = PythonOperator(
        task_id="write_file",
        python_callable=write_file,
    )

    build_text_task >> write_file_task
