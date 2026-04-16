from pyspark.sql import SparkSession


PATH = "s3a://spark/airflow-smoke/minio-basic"


def main() -> None:
    spark = SparkSession.builder.appName("airflow-spark-minio-demo").getOrCreate()

    rows = [(1, "ana"), (2, "bruno"), (3, "carla")]
    df = spark.createDataFrame(rows, ["id", "nome"])
    df.write.mode("overwrite").parquet(PATH)

    out = spark.read.parquet(PATH)
    count = out.count()
    out.orderBy("id").show(truncate=False)
    print(f"MINIO_BASIC_COUNT={count}")

    if count != 3:
        raise RuntimeError(f"Esperabamos 3 filas en {PATH} e obtivemos {count}")

    spark.stop()


if __name__ == "__main__":
    main()
