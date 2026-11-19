"""Run inside the candidate notebook image, passing the baseline JSON path.

Uses a real Jupyter kernel, Spark local mode and disposable local data.
This does not replace the U1 checks on YARN, HDFS and SeaweedFS.
"""

import importlib.metadata as metadata
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

import nbformat
from nbclient import NotebookClient


def canonical(name):
    return re.sub(r"[-_.]+", "-", name).lower()


baseline = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
installed = {
    canonical(dist.metadata["Name"]): dist.version
    for dist in metadata.distributions()
    if dist.metadata.get("Name")
}
differences = {
    package["name"]: {
        "before": package["version"],
        "now": installed.get(canonical(package["name"])),
    }
    for package in baseline["environment"]["packages"]
    if installed.get(canonical(package["name"])) != package["version"]
}
if differences:
    raise RuntimeError("Baseline packages changed or missing: " + json.dumps(differences))
if installed.get("great-expectations") != "1.25.0":
    raise RuntimeError("Expected GX 1.25.0")

check = subprocess.run(
    [sys.executable, "-m", "pip", "check"], capture_output=True, text=True
)
previous_errors = set(baseline["environment"]["pip_check"]["stdout"].splitlines())
new_errors = set(check.stdout.strip().splitlines()) - previous_errors
if check.returncode not in (0, 1) or check.stderr.strip() or new_errors:
    raise RuntimeError("New pip check errors: " + check.stdout + check.stderr)
print("Existing packages unchanged; GX 1.25.0 installed; no new dependency errors.", flush=True)

with tempfile.TemporaryDirectory(prefix="notebook-gx-") as work:
    code = """
import great_expectations as gx
import great_expectations.expectations as gxe
import pandas, numpy, delta, kafka, matplotlib, seaborn, plotly, ipywidgets
import findspark
findspark.init('/opt/spark')
from pyspark.sql import SparkSession
spark = (SparkSession.builder.master('local[2]').appName('notebook-gx-verification')
    .config('spark.eventLog.enabled', 'false')
    .config('spark.dynamicAllocation.enabled', 'false')
    .config('spark.driver.host', '127.0.0.1')
    .config('spark.driver.bindAddress', '127.0.0.1')
    .config('spark.default.parallelism', '2')
    .config('spark.sql.shuffle.partitions', '2')
    .config('spark.ui.showConsoleProgress', 'false')
    .config('spark.sql.catalog.gxprobe', 'org.apache.iceberg.spark.SparkCatalog')
    .config('spark.sql.catalog.gxprobe.type', 'hadoop')
    .config('spark.sql.catalog.gxprobe.warehouse', WORK_URI + '/iceberg')
    .config('spark.sql.warehouse.dir', WORK_URI + '/warehouse')
    .getOrCreate())
spark.sparkContext.setLogLevel('ERROR')
try:
    context = gx.get_context(mode='file', project_root_dir=WORK_DIR)
    context.variables.progress_bars = {'globally': False}
    source = context.data_sources.add_spark(name='spark')
    batch = source.add_dataframe_asset(name='rows').add_batch_definition_whole_dataframe('all')
    suite = context.suites.add(gx.ExpectationSuite(name='quality'))
    suite.add_expectation(gxe.ExpectColumnValuesToNotBeNull(column='name'))
    suite.add_expectation(gxe.ExpectColumnValuesToBeUnique(column='id'))
    suite.add_expectation(gxe.ExpectColumnValuesToBeBetween(column='amount', min_value=0))
    definition = context.validation_definitions.add(
        gx.ValidationDefinition(name='check', data=batch, suite=suite))
    good = spark.createDataFrame([(1, 'a', 10), (2, 'b', 20)],
        'id long, name string, amount long')
    bad = spark.createDataFrame([(1, None, -1), (1, 'b', 20)], good.schema)
    assert definition.run(batch_parameters={'dataframe': good}).success
    invalid = definition.run(batch_parameters={'dataframe': bad})
    assert not invalid.success
    assert invalid.statistics['unsuccessful_expectations'] == 3
    spark.sql('CREATE NAMESPACE gxprobe.study')
    good.writeTo('gxprobe.study.rows').tableProperty('format-version', '2').create()
    assert definition.run(batch_parameters={'dataframe': spark.table('gxprobe.study.rows')}).success
    good.write.format('delta').save(WORK_URI + '/delta')
    assert spark.read.format('delta').load(WORK_URI + '/delta').count() == 2
    docs = context.build_data_docs()
    assert docs
    from pathlib import Path
    from urllib.parse import urlparse, unquote
    assert all(Path(unquote(urlparse(url).path)).is_file() for url in docs.values())
    print('PASS: Jupyter kernel, GX valid/invalid data, Iceberg, Delta and HTML reports.')
finally:
    spark.stop()
"""
    prefix = "WORK_DIR = " + repr(work) + "\nWORK_URI = " + repr(Path(work).as_uri()) + "\n"
    notebook = nbformat.v4.new_notebook(cells=[nbformat.v4.new_code_cell(prefix + code)])
    try:
        NotebookClient(notebook, timeout=180, kernel_name="python3").execute()
    finally:
        for cell in notebook.cells:
            for output in cell.get("outputs", []):
                if output.output_type == "stream":
                    print(output.text)
                elif output.output_type == "error":
                    print(output.ename, output.evalue)
