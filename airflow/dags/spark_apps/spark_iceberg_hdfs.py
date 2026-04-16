from pyspark.sql import SparkSession


TABLE = "local.demo_airflow.people"


def main() -> None:
    spark = SparkSession.builder.appName("airflow-spark-iceberg-hdfs-demo").getOrCreate()

    spark.sql("CREATE NAMESPACE IF NOT EXISTS local.demo_airflow")
    spark.sql(f"DROP TABLE IF EXISTS {TABLE}")
    spark.sql(f"CREATE TABLE {TABLE} (id BIGINT, nome STRING) USING iceberg")
    spark.sql(f"INSERT INTO {TABLE} VALUES (1, 'ana'), (2, 'bruno')")
    spark.sql(f"INSERT INTO {TABLE} VALUES (3, 'carla')")

    out = spark.sql(f"SELECT * FROM {TABLE} ORDER BY id")
    count = out.count()
    out.show(truncate=False)
    print(f"ICEBERG_HDFS_COUNT={count}")

    if count != 3:
        raise RuntimeError(f"Esperabamos 3 filas Iceberg en {TABLE} e obtivemos {count}")

    spark.stop()


if __name__ == "__main__":
    main()
