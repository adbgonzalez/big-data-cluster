"""Validate disposable Iceberg tables on HDFS using the real YARN cluster."""

import argparse
import json
from pathlib import Path
import socket
import uuid

import great_expectations as gx
import great_expectations.expectations as gxe
from pyspark.sql import SparkSession


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--case", choices=("valid", "invalid"), required=True)
    args = parser.parse_args()
    run_id = uuid.uuid4().hex
    warehouse = f"hdfs://namenode:9000/tmp/gx-airflow-validation/iceberg/{run_id}"
    output = Path("/opt/airflow/logs/gx-validation") / run_id
    output.mkdir(parents=True, exist_ok=True)

    spark = (
        SparkSession.builder.appName(f"gx-airflow-{args.case}")
        .config("spark.driver.host", socket.gethostname())
        .config("spark.driver.bindAddress", "0.0.0.0")
        .config("spark.sql.catalog.gxprobe", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.gxprobe.type", "hadoop")
        .config("spark.sql.catalog.gxprobe.warehouse", warehouse)
        .getOrCreate()
    )
    spark.sparkContext.setLogLevel("WARN")
    try:
        if spark.sparkContext.master != "yarn":
            raise RuntimeError("This check must run on YARN, not Spark local mode")
        rows = [(1, "Ana", 10), (2, "Brais", 20)]
        if args.case == "invalid":
            rows = [(1, None, -1), (1, "Brais", 20)]
        dataframe = spark.createDataFrame(rows, "id long, name string, amount long")
        spark.sql("CREATE NAMESPACE gxprobe.study")
        dataframe.writeTo("gxprobe.study.rows").tableProperty("format-version", "2").create()

        context = gx.get_context(mode="file", project_root_dir=str(output))
        context.variables.progress_bars = {"globally": False}
        source = context.data_sources.add_spark(name="spark_yarn")
        batch = source.add_dataframe_asset(name="iceberg_rows").add_batch_definition_whole_dataframe("all")
        suite = context.suites.add(gx.ExpectationSuite(name="quality"))
        suite.add_expectation(gxe.ExpectColumnValuesToNotBeNull(column="name"))
        suite.add_expectation(gxe.ExpectColumnValuesToBeUnique(column="id"))
        suite.add_expectation(gxe.ExpectColumnValuesToBeBetween(column="amount", min_value=0))
        definition = context.validation_definitions.add(
            gx.ValidationDefinition(name="check", data=batch, suite=suite)
        )
        result = definition.run(batch_parameters={"dataframe": spark.table("gxprobe.study.rows")})
        summary = {
            "case": args.case,
            "success": result.success,
            "failed_rules": result.statistics["unsuccessful_expectations"],
            "master": spark.sparkContext.master,
            "application_id": spark.sparkContext.applicationId,
            "warehouse": warehouse,
        }
        (output / "result.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        context.build_data_docs()
        print("GX_YARN_RESULT " + json.dumps(summary), flush=True)
        if not result.success:
            raise RuntimeError("GX_VALIDATION_FAILED: the data violates the quality rules")
        print("GX_VALIDATION_PASSED", flush=True)
    finally:
        spark.stop()


if __name__ == "__main__":
    main()
