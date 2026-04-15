from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator


def check_pyspark() -> None:
    import pyspark

    print(f"PySpark dispoible. Version: {pyspark.__version__}")


def run_local_spark_job() -> None:
    from pyspark.sql import SparkSession

    spark = (
        SparkSession.builder
        .appName("airflow-spark-local-demo")
        .master("local[*]")
        .getOrCreate()
    )

    total = spark.range(1, 11).selectExpr("sum(id) as total").collect()[0]["total"]
    print(f"Resultado do calculo Spark: {total}")

    spark.stop()


with DAG(
    dag_id="spark_local_demo_airflow",
    description="DAG simple para comprobar PySpark cunha execucion local.",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo", "spark"],
) as dag:
    check_pyspark_task = PythonOperator(
        task_id="check_pyspark",
        python_callable=check_pyspark,
    )

    run_local_spark_task = PythonOperator(
        task_id="run_local_spark_job",
        python_callable=run_local_spark_job,
    )

    check_pyspark_task >> run_local_spark_task
