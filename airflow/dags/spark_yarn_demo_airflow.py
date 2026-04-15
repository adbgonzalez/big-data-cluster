from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.providers.standard.operators.python import PythonOperator


def run_yarn_spark_job() -> None:
    from pyspark.sql import SparkSession

    spark = (
        SparkSession.builder
        .appName("airflow-spark-yarn-demo")
        .master("yarn")
        .config("spark.submit.deployMode", "client")
        .config("spark.eventLog.enabled", "true")
        .config("spark.eventLog.dir", "hdfs://namenode:9000/spark-logs")
        .getOrCreate()
    )

    total = spark.range(1, 11).selectExpr("sum(id) as total").collect()[0]["total"]
    print(f"Resultado do calculo Spark sobre YARN: {total}")

    spark.stop()


with DAG(
    dag_id="spark_yarn_demo_airflow",
    description="DAG simple para probar Spark sobre YARN desde Airflow.",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo", "spark", "yarn"],
) as dag:
    run_yarn_spark_task = PythonOperator(
        task_id="run_yarn_spark_job",
        python_callable=run_yarn_spark_job,
    )
