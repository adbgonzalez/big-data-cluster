from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator


with DAG(
    dag_id="spark_submit_demo_airflow",
    description="DAG simple que lanza unha aplicacion PySpark con SparkSubmitOperator sobre YARN.",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo", "spark", "yarn", "spark-submit"],
) as dag:
    SparkSubmitOperator(
        task_id="run_spark_submit_job",
        application="/opt/airflow/dags/spark_apps/spark_range_sum.py",
        conn_id="spark_default",
        spark_binary="/home/airflow/.local/bin/spark-submit",
        name="airflow-spark-submit-demo",
        env_vars={
            "HADOOP_CONF_DIR": "/opt/hadoop-conf",
            "SPARK_CONF_DIR": "/opt/spark/conf",
        },
    )
