"""Two manual integration checks: valid data succeeds, invalid data fails."""

from datetime import datetime, timedelta, timezone

from airflow.sdk import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator


for case, dag_name in (
    ("valid", "gx_yarn_correctos"),
    ("invalid", "gx_yarn_con_erros"),
):
    with DAG(
        dag_id=dag_name,
        start_date=datetime(2026, 1, 1, tzinfo=timezone.utc),
        schedule=None,
        catchup=False,
        is_paused_upon_creation=True,
        max_active_runs=1,
        tags=["proba", "gx", "yarn"],
    ) as dag:
        SparkSubmitOperator(
            task_id="validar_iceberg",
            application="/opt/airflow/jobs/gx_yarn_validation.py",
            application_args=["--case", case],
            conn_id="spark_default",
            pool="gx_yarn_validation",
            deploy_mode="client",
            executor_cores=1,
            executor_memory="1g",
            driver_memory="1g",
            num_executors=1,
            conf={
                "spark.dynamicAllocation.enabled": "false",
                "spark.executor.memoryOverhead": "512m",
                "spark.default.parallelism": "2",
                "spark.sql.shuffle.partitions": "2",
                "spark.eventLog.enabled": "false",
                "spark.yarn.stagingDir": "hdfs://namenode:9000/tmp/gx-airflow-validation/staging",
            },
            retries=0,
            execution_timeout=timedelta(minutes=10),
        )
    globals()[dag_name] = dag
