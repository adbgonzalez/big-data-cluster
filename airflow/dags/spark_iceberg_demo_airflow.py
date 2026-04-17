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
    "spark.hadoop.fs.s3a.endpoint": "http://minio:9000",
    "spark.hadoop.fs.s3a.access.key": "minioadmin",
    "spark.hadoop.fs.s3a.secret.key": "minioadmin",
    "spark.hadoop.fs.s3a.path.style.access": "true",
    "spark.hadoop.fs.s3a.connection.ssl.enabled": "false",
    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem",
    "spark.hadoop.fs.s3a.aws.credentials.provider": (
        "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"
    ),
    "spark.hadoop.fs.s3a.input.stream.type": "classic",
    "spark.hadoop.fs.s3a.change.detection.mode": "none",
    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
    "spark.sql.catalog.minio": "org.apache.iceberg.spark.SparkCatalog",
    "spark.sql.catalog.minio.type": "hadoop",
    "spark.sql.catalog.minio.warehouse": "s3a://spark/iceberg-warehouse",
}


with DAG(
    dag_id="spark_iceberg_demo_airflow",
    description="Smoke test de Iceberg sobre MinIO en client mode.",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo", "spark", "yarn", "iceberg", "minio"],
) as dag:
    SparkSubmitOperator(
        task_id="run_spark_iceberg_job",
        application="/opt/airflow/dags/spark_apps/spark_iceberg_minio.py",
        conn_id="spark_default",
        spark_binary="/home/airflow/.local/bin/spark-submit",
        name="airflow-spark-iceberg-demo-client",
        deploy_mode="client",
        conf=COMMON_CONF,
        env_vars={
            "HADOOP_CONF_DIR": "/opt/hadoop-conf",
            "SPARK_CONF_DIR": "/opt/spark/conf",
            "PYSPARK_PYTHON": "python3",
            "PYSPARK_DRIVER_PYTHON": "python3",
        },
    )
