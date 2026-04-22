from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator

def saudar():
    print("Ola, Airflow!")

with DAG(
    dag_id="hello_airflow",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["exemplo","python"],
) as dag:
    tarefa_saudar = PythonOperator(
        task_id="tarefa_saudar",
        python_callable=saudar,
    )
    tarefa_saudar