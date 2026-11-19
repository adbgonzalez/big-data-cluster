"""Smoke test for the Airflow GX candidate, with disposable local data.

Run with the Airflow Spark configuration mounted and with networking disabled.
An actual Airflow task on YARN must still be checked separately.
"""

import importlib.metadata as metadata
import os
from pathlib import Path
import subprocess
import sys
import tempfile

import airflow
from airflow.providers.apache.kafka.hooks.produce import KafkaProducerHook
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
import great_expectations as gx
import great_expectations.expectations as gxe
from pyspark.sql import SparkSession


expected = {
    "apache-airflow": "3.1.8",
    "apache-airflow-providers-apache-spark": "5.5.1",
    "pyspark": "4.1.1",
    "great-expectations": "1.25.0",
}
for name, version in expected.items():
    actual = metadata.version(name)
    if actual != version:
        raise RuntimeError(f"Expected {name} {version}, got {actual}")
if sys.version_info[:2] != (3, 12):
    raise RuntimeError("Python 3.12 required to match the YARN executors")
check = subprocess.run(
    [sys.executable, "-m", "pip", "check"], capture_output=True, text=True
)
if check.returncode:
    raise RuntimeError(check.stdout + check.stderr)
print("PASS: Airflow and provider imports, pinned versions and pip check.", flush=True)

# Use the current interpreter in this local test. YARN Python paths are a
# separate deployment concern; no settings in the cluster are modified here.
os.environ["PYSPARK_PYTHON"] = sys.executable
os.environ["PYSPARK_DRIVER_PYTHON"] = sys.executable
with tempfile.TemporaryDirectory(prefix="airflow-gx-") as work:
    uri = Path(work).as_uri()
    spark = (
        SparkSession.builder.master("local[2]")
        .appName("airflow-gx-verification")
        .config("spark.eventLog.enabled", "false")
        .config("spark.dynamicAllocation.enabled", "false")
        .config("spark.driver.host", "127.0.0.1")
        .config("spark.driver.bindAddress", "127.0.0.1")
        .config("spark.default.parallelism", "2")
        .config("spark.sql.shuffle.partitions", "2")
        .config("spark.ui.showConsoleProgress", "false")
        .config("spark.sql.catalog.gxprobe", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.gxprobe.type", "hadoop")
        .config("spark.sql.catalog.gxprobe.warehouse", uri + "/iceberg")
        .config("spark.sql.warehouse.dir", uri + "/warehouse")
        .getOrCreate()
    )
    spark.sparkContext.setLogLevel("ERROR")
    try:
        assert spark.version == "4.1.1"
        context = gx.get_context(mode="file", project_root_dir=work)
        context.variables.progress_bars = {"globally": False}
        source = context.data_sources.add_spark(name="spark")
        batch = source.add_dataframe_asset(name="rows").add_batch_definition_whole_dataframe("all")
        suite = context.suites.add(gx.ExpectationSuite(name="quality"))
        suite.add_expectation(gxe.ExpectColumnValuesToNotBeNull(column="name"))
        suite.add_expectation(gxe.ExpectColumnValuesToBeUnique(column="id"))
        definition = context.validation_definitions.add(
            gx.ValidationDefinition(name="check", data=batch, suite=suite)
        )
        good = spark.createDataFrame([(1, "a"), (2, "b")], "id long, name string")
        bad = spark.createDataFrame([(1, None), (1, "b")], good.schema)
        assert definition.run(batch_parameters={"dataframe": good}).success
        invalid = definition.run(batch_parameters={"dataframe": bad})
        assert not invalid.success
        assert invalid.statistics["unsuccessful_expectations"] == 2
        spark.sql("CREATE NAMESPACE gxprobe.study")
        good.writeTo("gxprobe.study.rows").tableProperty("format-version", "2").create()
        assert definition.run(batch_parameters={"dataframe": spark.table("gxprobe.study.rows")}).success
        assert context.build_data_docs()
        print("PASS: GX valid/invalid data, Spark, Iceberg and HTML reports.", flush=True)
    finally:
        spark.stop()
