from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator


COMMON_CONF = {
    "spark.yarn.appMasterEnv.HADOOP_CONF_DIR": "/opt/hadoop-conf",
    "spark.yarn.appMasterEnv.SPARK_CONF_DIR": "/opt/spark/conf",
    "spark.yarn.appMasterEnv.PYSPARK_PYTHON": "python3",
    "spark.executorEnv.PYSPARK_PYTHON": "python3",
    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
    "spark.sql.catalog.local": "org.apache.iceberg.spark.SparkCatalog",
    "spark.sql.catalog.local.type": "hadoop",
    "spark.sql.catalog.local.warehouse": "hdfs://namenode:9000/user/airflow/warehouse/iceberg",
}


with DAG(
    dag_id="spark_iceberg_hdfs_demo_airflow",
    description="Smoke test de Iceberg sobre HDFS.",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo", "spark", "yarn", "iceberg", "hdfs"],
) as dag:
    SparkSubmitOperator(
        task_id="run_spark_iceberg_hdfs_job",
        application="/opt/airflow/dags/spark_apps/spark_iceberg_hdfs.py",
        conn_id="spark_default",
        spark_binary="/home/airflow/.local/bin/spark-submit",
        name="airflow-spark-iceberg-hdfs-demo",
        deploy_mode="cluster",
        conf=COMMON_CONF,
        env_vars={
            "HADOOP_CONF_DIR": "/opt/hadoop-conf",
            "SPARK_CONF_DIR": "/opt/spark/conf",
        },
    )
