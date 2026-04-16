from pyspark.sql import SparkSession


PATH = "hdfs://namenode:9000/user/airflow/airflow-smoke/delta-people"


def main() -> None:
    spark = SparkSession.builder.appName("airflow-spark-delta-hdfs-demo").getOrCreate()

    base = spark.createDataFrame([(1, "ana"), (2, "bruno")], ["id", "nome"])
    base.write.format("delta").mode("overwrite").save(PATH)

    more = spark.createDataFrame([(3, "carla")], ["id", "nome"])
    more.write.format("delta").mode("append").save(PATH)

    out = spark.read.format("delta").load(PATH)
    count = out.count()
    out.orderBy("id").show(truncate=False)
    print(f"DELTA_HDFS_COUNT={count}")

    if count != 3:
        raise RuntimeError(f"Esperabamos 3 filas Delta en {PATH} e obtivemos {count}")

    spark.stop()


if __name__ == "__main__":
    main()
