# Exame 1: iniciar o contorno

## 1. Preparar

O contorno debe estar copiado en `D:\entorno_bda`, coas carpetas `images`, `big-data-lab\big-data-cluster` e `big-data-lab\spark-notebooks`.

Abre Docker Desktop e agarda a que estea listo. Debe usar contedores Linux.

Abre PowerShell e executa:

```powershell
cd D:\entorno_bda\big-data-lab\big-data-cluster
```

## 2. Cargar as imaxes (só a primeira vez)

Agarda a que remate cada comando. Se falla, avisa ao profesor.

```powershell
docker load -i D:\entorno_bda\images\exame1-images.tar
```

## 3. Arrancar

```powershell
docker compose -f compose.base.yml -f compose.postgres.yml -f compose.seaweedfs.yml up -d --pull never --no-build
```

Agarda a que arranquen os servizos. Se aparece un erro de imaxe ausente, revisa o paso 2.

## 4. Abrir e comprobar

- Jupyter: http://localhost:8888

En Jupyter, abre un notebook de Python e executa:

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()
print(spark.sparkContext.master)
print(spark.range(10).count())
```

Debe mostrar `yarn` e `10`. A primeira execución pode tardar. Despois, abre o notebook do exame.

## 5. Parar ao rematar

Garda o notebook e executa:

```powershell
docker compose -f compose.base.yml -f compose.postgres.yml -f compose.seaweedfs.yml stop
```

Para volver traballar, repite o paso 3.

## Se algo falla

Consulta o estado dos servizos:

```powershell
docker compose -f compose.base.yml -f compose.postgres.yml -f compose.seaweedfs.yml ps -a
```

Para ver os últimos erros de Jupyter:

```powershell
docker logs spark-notebook --tail 50
```

Se o problema continúa, avisa ao profesor co erro que aparece.
