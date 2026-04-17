from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator


COMMON_CONF = {
    "spark.submit.deployMode": "client",
    "spark.yarn.appMasterEnv.HADOOP_CONF_DIR": "/opt/hadoop-conf",
    "spark.yarn.appMasterEnv.SPARK_CONF_DIR": "/opt/spark/conf",
    "spark.yarn.appMasterEnv.PYSPARK_PYTHON": "python3",
    "spark.executorEnv.PYSPARK_PYTHON": "python3",
    "spark.pyspark.python": "python3",
    "spark.sql.extensions": "io.delta.sql.DeltaSparkSessionExtension",
    "spark.sql.catalog.spark_catalog": "org.apache.spark.sql.delta.catalog.DeltaCatalog",
}


with DAG(
    dag_id="spark_delta_hdfs_demo_airflow",
    description="Smoke test de Delta Lake sobre HDFS en client mode.",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo", "spark", "yarn", "delta", "hdfs"],
) as dag:
    SparkSubmitOperator(
        task_id="run_spark_delta_hdfs_job",
        application="/opt/airflow/dags/spark_apps/spark_delta_hdfs.py",
        conn_id="spark_default",
        spark_binary="/home/airflow/.local/bin/spark-submit",
        name="airflow-spark-delta-hdfs-demo-client",
        deploy_mode="client",
        packages="io.delta:delta-spark_2.13:4.1.0",
        conf=COMMON_CONF,
        env_vars={
            "HADOOP_CONF_DIR": "/opt/hadoop-conf",
            "SPARK_CONF_DIR": "/opt/spark/conf",
            "PYSPARK_PYTHON": "python3",
            "PYSPARK_DRIVER_PYTHON": "python3",
        },
    )
