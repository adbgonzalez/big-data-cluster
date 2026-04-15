from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("airflow-spark-submit-demo")
    .getOrCreate()
)

try:
    total = spark.range(1, 11).selectExpr("sum(id) as total").collect()[0]["total"]
    print(f"Resultado do calculo SparkSubmit: {total}")
finally:
    spark.stop()
