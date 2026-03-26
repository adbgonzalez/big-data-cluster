# big-data-cluster

Este repositorio contén un **entorno modular de big data en docker compose** pensado para docencia e probas locais.  
Inclúe un clúster base **hadoop (hdfs + yarn) + spark + jupyterlab**, e módulos opcionais para completar un ecosistema típico de enxeñaría de datos:

- kafka (+ kafka ui)
- minio (s3)
- apache nifi
- apache zeppelin
- apache superset

O deseño é incremental: primeiro levántase o clúster base e, segundo as necesidades, actívanse os módulos adicionais.

---

## imaxes docker empregadas

Este proxecto usa varias imaxes personalizadas publicadas en docker hub (todas as que comezan por `adbgonzalez`):

- `adbgonzalez/spark:3.5.7`  
  imaxe base do clúster: hadoop + yarn + spark (inclúe scripts e configuración para executar spark sobre yarn)

- `adbgonzalez/spark-notebook:3.5.7`  
  jupyterlab listo para pyspark, configurado para enviar aplicacións a yarn, con soporte para jars adicionais (`/opt/spark/jars-extra`)

- `adbgonzalez/kafka:3.9`  
  kafka en modo kraft (sen zookeeper) cunha configuración simplificada para uso local

- `adbgonzalez/zeppelin:0.12.0`  
  zeppelin integrado con yarn + hadoop, e preparado para executar spark como backend

> nota: minio, nifi e superset usan imaxes oficiais (`minio/minio`, `apache/nifi`, `apache/superset`, etc.).

---

## requisitos

- windows 10/11 ou linux
- docker compose v2
- recomendado: 16 gb ram mínimo (ideal 32 gb)
- espazo en disco: o uso de volumes persistentes (hdfs/kafka/minio) pode medrar rapidamente

---

## composición modular do clúster

O proxecto está dividido en varios ficheiros compose, para activar só o que se precisa:

- `compose.base.yml` → clúster base (hdfs + yarn + spark + jupyter + history server)
- `compose.kafka.yml` → kafka + kafka ui (redpanda console)
- `compose.minio.yml` → minio (s3)
- `compose.nifi.yml` → apache nifi (depende de minio e namenode)
- `compose.superset.yml` → superset + postgres + redis
- `compose.zeppelin.yml` → zeppelin integrado con yarn/spark

---

## estrutura do repositorio

```
.
├── compose.base.yml
├── compose.kafka.yml
├── compose.minio.yml
├── compose.nifi.yml
├── compose.superset.yml
├── compose.zeppelin.yml
│
├── conf/                 # configuración xml de hadoop (core/hdfs/yarn/mapred)
├── spark-conf/           # configuración específica de spark (spark-defaults.conf)
├── zeppelin-conf/        # configuración de zeppelin (se aplica)
│
├── jupyter/              # dockerfile + dependencias do contedor jupyterlab
├── kafka/                # recursos e configuración asociados a kafka (se aplica)
├── zeppelin/             # recursos / dockerfile de zeppelin (se aplica)
│
├── jars/                 # jars auxiliares para Zeppelin/Spark (volume opcional)
├── zeppelin-notebooks/   # notebooks persistentes de Zeppelin
├── scripts/              # scripts .ps1/.sh para arranque, parada e utilidades
│   ├── up-base.ps1
│   ├── up-kafka.ps1
│   ├── up-minio.ps1
│   ├── up-nifi.ps1
│   ├── up-zeppelin.ps1
│   ├── up-all.ps1
│   ├── down.ps1
│   ├── down-v.ps1
│   ├── down-all.ps1
│   ├── logs-ui.ps1
│   ├── logs-kafka.ps1
│   ├── logs-nifi.ps1
│   ├── logs-notebook.ps1
│   ├── ps.ps1
│   ├── prep-exame.ps1
│   ├── reset-checkpoints.ps1
│   ├── reset-checkpoints.sh
│   ├── reset-kafka-topics.ps1
│   └── reset-kafka-topics.sh
│
└── README.md
```

---

## estrutura de traballo recomendada (alumnado)

Este clúster está pensado para usarse xunto cun repositorio separado de notebooks de Spark.
Para evitar repositorios Git aniñados e facilitar o traballo, **ambos repositorios deben clonarse ao mesmo nivel**, dentro dun cartafol de traballo común.

A estrutura recomendada é a seguinte:
```bash
big-data-lab/ ← cartafol de traballo (non é repositorio git)
├── big-data-cluster/ ← este repositorio
└── spark-notebooks/ ← repositorio de notebooks de Spark
```


⚠️ **É importante que o cartafol dos notebooks se chame exactamente `spark-notebooks`**, xa que o contedor de Jupyter monta ese directorio como volume.

### clonado dos repositorios

```bash
mkdir big-data-lab
cd big-data-lab

git clone https://github.com/adbgonzalez/big-data-cluster big-data-cluster
git clone https://github.com/adbgonzalez/notebooks-spark-25-26 spark-notebooks

```
Unha vez clonados os dous repositorios, o clúster debe arrancarse desde o directorio **big-data-cluster/scripts**, tal e como se describe no apartado seguinte.

---

## inicio rápido (windows)

> en windows, a forma recomendada é usar os scripts `.ps1`.

### 1) arrancar o clúster base

```powershell
.\up-base.ps1
```

Isto levanta:
- namenode + datanode (hdfs)
- resourcemanager + nodemanager (yarn)
- spark history server
- jupyterlab (pyspark)

Para ver contedores activos:

```powershell
.\ps.ps1
```

Para consultar logs principais:

```powershell
.\logs-ui.ps1
```

---

### 2) activar módulos opcionais

#### kafka + kafka ui
```powershell
.\up-kafka.ps1
.\logs-kafka.ps1
```

#### minio (s3)
```powershell
.\up-minio.ps1
```

#### nifi (depende de minio + namenode)
```powershell
.\up-nifi.ps1
.\logs-nifi.ps1
```

#### zeppelin
```powershell
.\up-zeppelin.ps1
```

#### superset
```powershell
docker compose -f compose.base.yml -f compose.superset.yml up -d
```

---

### 3) levantar todo (base + módulos)
```powershell
.\up-all.ps1
```

---

## interfaces web 

### clúster base
| servizo | url | descrición |
|--------|-----|------------|
| jupyterlab | http://localhost:8888 | notebooks con pyspark |
| hdfs namenode | http://localhost:9870 | navegador de hdfs |
| yarn resourcemanager | http://localhost:8088 | seguimento de aplicacións |
| spark history server | http://localhost:18080 | histórico de aplicacións spark |

### kafka
| servizo | url | descrición |
|--------|-----|------------|
| kafka broker | localhost:9092 | acceso desde host |
| kafka ui | http://localhost:8089 | redpanda console |

### minio
| servizo | url | descrición |
|--------|-----|------------|
| consola web | http://localhost:9001 | panel de administración |
| api s3 | http://localhost:9002 | endpoint s3 (port 9000 interno) |

credenciais por defecto:
- user: `minioadmin`
- pass: `minioadmin`

(pódense cambiar con `MINIO_ROOT_USER` e `MINIO_ROOT_PASSWORD`)

### nifi
| servizo | url | descrición |
|--------|-----|------------|
| nifi (https) | https://localhost:9091 | ui web |

credenciais por defecto:
- user: `admin`
- pass: `Admin.BDA123!`

(pódense cambiar con `NIFI_USER` e `NIFI_PASS`)

### zeppelin
| servizo | url | descrición |
|--------|-----|------------|
| zeppelin | http://localhost:8081 | notebooks |

### superset
| servizo | url | descrición |
|--------|-----|------------|
| superset | http://localhost:8090 | bi e dashboards |

credenciais por defecto:
- user: `admin`
- pass: `admin`

---

## exemplo rápido: spark sobre yarn desde jupyterlab

Abre http://localhost:8888 e crea un notebook python.

```python
import findspark
findspark.init("/opt/spark")

from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("test-yarn")
    .master("yarn")
    .config("spark.eventLog.enabled", "true")
    .config("spark.eventLog.dir", "hdfs://namenode:9000/spark-logs")
    .getOrCreate()
)

spark.range(1, 1000000).selectExpr("sum(id)").show()
```

O resultado debería aparecer tamén no history server (http://localhost:18080).

---

## xestión do clúster

### parar servizos (sen borrar volumes)
```powershell
.\down.ps1
```

### parar e borrar volumes (⚠️ elimina datos persistentes)
```powershell
.\down-v.ps1
```

### parar todo (incluíndo módulos)
```powershell
.\down-all.ps1
```

---

## utilidades

### reset de checkpoints (streaming)
```powershell
.\reset-checkpoints.ps1
```

ou en linux:
```bash
./reset-checkpoints.sh
```

### reset de tópicos kafka
```powershell
.\reset-kafka-topics.ps1
```

ou en linux:
```bash
./reset-kafka-topics.sh
```


---

## créditos

mantido por **adrián blanco (cifp a carballeira)**
