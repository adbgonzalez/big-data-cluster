# big-data-cluster

## finais de liña

O repositorio inclúe un `.gitattributes` que forza finais de liña LF nos ficheiros que se montan ou executan dentro dos contedores (scripts `.sh`, ficheiros compose, configuración de Hadoop/Spark, Dockerfiles), sexa cal sexa a configuración de Git do equipo. Xa non é necesario configurar `core.autocrlf` antes de clonar; se o tiñas en `input`, non pasa nada.

Este repositorio contén un **entorno modular de big data en docker compose** pensado para docencia e probas locais.  
Inclúe un clúster base **hadoop (hdfs + yarn) + spark + jupyterlab**, e módulos opcionais para completar un ecosistema típico de enxeñaría de datos:

- kafka (+ kafka ui)
- seaweedfs (s3)
- apache nifi
- apache airflow
- apache superset


O deseño é incremental: primeiro levántase o clúster base e, segundo as necesidades, actívanse os módulos adicionais.

---

## imaxes docker empregadas

Este proxecto usa varias imaxes personalizadas publicadas en docker hub (todas as que comezan por `adbgonzalez`):

- `adbgonzalez/spark:4.1.1-py312`  
  imaxe base do clúster: hadoop + yarn + spark (inclúe scripts e configuración para executar spark sobre yarn)

- `adbgonzalez/spark-notebook:4.1.1-py312`  
  jupyterlab listo para pyspark, configurado para enviar aplicacións a yarn, con soporte para jars adicionais (`/opt/spark/jars-extra`) e GX Core 1.25.0 na imaxe local actualizada (publicación pendente)

- `adbgonzalez/hadoop:3.4.3-py312`  
  imaxe base para o stack hadoop legado definido en `compose.hadoop.yml`

- `adbgonzalez/airflow:3.1.8`  
  imaxe personalizada de Airflow para este stack, con GX Core 1.25.0 na imaxe local actualizada (publicación pendente) e providers definidos en `airflow/requirements.txt`

- `adbgonzalez/kafka:3.9`  
  kafka en modo kraft (sen zookeeper) cunha configuración simplificada para uso local

> nota: seaweedfs, nifi e superset usan imaxes oficiais (`chrislusf/seaweedfs`, `apache/nifi`, `apache/superset`, etc.).

### construción do notebook con Great Expectations

O Dockerfile de `jupyter/` incorpora GX Core 1.25.0. Para conservar as versións
do notebook rexistrado antes de engadir GX, usa `jupyter/baseline/constraints-existing.txt`;
as novas dependencias están fixadas en `jupyter/constraints-gx.txt`. Estes ficheiros
deben acompañar a `requirements.txt` ao construír a imaxe. O inventario completo
e a identificación da imaxe anterior están en `jupyter/baseline/notebook-baseline.json`.
Isto fixa os paquetes Python; a imaxe base de Spark debe ser a mesma que se validou.

O 19 de novembro de 2026, a imaxe con GX quedou como imaxe local habitual coa
etiqueta `adbgonzalez/spark-notebook:4.1.1-py312`, que xa usan os Compose.
O usuario confirmou que funcionan os exercicios da unidade 1 probados.
Tamén se superaron as probas locais sen rede de Jupyter, GX, Iceberg, Delta
e xeración de informes, conservando as versións de todos os paquetes anteriores.

Pendentes de distribución:

- [ ] Subir a imaxe actualizada `adbgonzalez/spark-notebook:4.1.1-py312` a Docker Hub.
- [ ] Subir a imaxe actualizada `adbgonzalez/airflow:3.1.8`, con GX e validada sobre YARN, a Docker Hub.
- [ ] Preparar máis adiante a exportación das imaxes a arquivos para o alumnado.

Ata completar a publicación, Docker Hub pode servir as imaxes anteriores do
notebook e de Airflow coas mesmas etiquetas. Evitar `docker pull` ou os scripts `update-images` sobre este contorno
local validado mentres esa subida siga pendente.

Para reconstruír a imaxe habitual:

```bash
docker build --pull=false --platform linux/amd64 -t adbgonzalez/spark-notebook:4.1.1-py312 ./jupyter
```

Desde a raíz do repositorio, esta proba en PowerShell comproba as versións e
executa un kernel Jupyter con Spark local, validacións GX, Iceberg, Delta e informes
HTML, sen rede nin acceso aos volumes do clúster:

```powershell
Get-Content -Raw ./scripts/verify-notebook-gx.py | docker run --rm -i --pull never --network none --hostname localhost --mount "type=bind,source=$((Resolve-Path ./jupyter/baseline).Path),target=/baseline,readonly" --entrypoint python3 adbgonzalez/spark-notebook:4.1.1-py312 - /baseline/notebook-baseline.json
```

Esta proba local non substitúe a execución dos exercicios da unidade 1 sobre YARN
e os seus almacenamentos antes de distribuír a imaxe ao alumnado.

### construción de Airflow con Great Expectations

O Dockerfile de `airflow/` incorpora GX Core 1.25.0 e PySpark 4.1.1, mantendo
Airflow 3.1.8. A instalación respecta as constraints oficiais da versión de
Airflow; `airflow/constraints-gx.txt` fixa as dependencias adicionais que non
figuran nelas. Non se reutilizan as constraints do notebook.

O 19 de novembro de 2026 a imaxe validada con GX quedou como imaxe local habitual
coa etiqueta `adbgonzalez/airflow:3.1.8`, que xa usan os Compose. A subida a Docker
Hub queda pendente. Para reconstruír a imaxe habitual:

```bash
docker build --pull=false --platform linux/amd64 -t adbgonzalez/airflow:3.1.8 ./airflow
```

Comprobación local en PowerShell, sen rede nin volumes de datos do clúster:

```powershell
Get-Content -Raw ./scripts/verify-airflow-gx.py | docker run --rm -i --pull never --network none --hostname localhost --mount "type=bind,source=$((Resolve-Path ./conf).Path),target=/opt/hadoop-conf,readonly" --mount "type=bind,source=$((Resolve-Path ./spark-conf/spark-defaults-airflow.conf).Path),target=/opt/spark/conf/spark-defaults.conf,readonly" --entrypoint python adbgonzalez/airflow:3.1.8 -
```

O 19 de novembro de 2026 construíuse a candidata e superou esta proba sen rede:
imports dos providers, dependencias, Spark local, validacións GX, Iceberg e
informes HTML. Tamén se superaron os dous casos reais sobre YARN descritos
a continuación. A imaxe habitual actualizada segue pendente de publicar en Docker Hub.

### proba de Airflow con GX sobre YARN

Desde a raíz do repositorio:

```powershell
.\scripts\up-airflow-gx-validation.ps1
```

O script usa a imaxe habitual e prepara os DAGs manuais en http://localhost:8091.
Activar e executar primeiro `gx_yarn_correctos`: debe rematar en verde. Despois,
executar `gx_yarn_con_erros`: debe rematar en vermello e o log de `validar_iceberg`
debe indicar `GX_VALIDATION_FAILED`. Un fallo de conexión ou de configuración
non conta como detección correcta de datos inválidos.

As tarefas crean e len táboas Iceberg sobre HDFS usando Spark sobre YARN.
Os resultados quedan en `airflow/logs/gx-validation/`, con `result.json` e
informes HTML. Un pool dunha praza evita executar as dúas tarefas á vez.

Proba confirmada polo usuario o 19 de novembro de 2026: o caso correcto rematou
con `success: true`, cero regras incumpridas e `GX_VALIDATION_PASSED`
(`application_1795107096440_0001`). O caso incorrecto detectou as tres regras
incumpridas, emitiu `GX_VALIDATION_FAILED` e Airflow marcou a tarefa como fallida
(`application_1795107096440_0002`). Ese fallo é o resultado esperado da proba negativa.

`compose.airflow-gx-validation.yml` utiliza volumes propios para HDFS e a base de
datos de Airflow; conserva os volumes habituais. O 19 de novembro detectouse que
o HDFS habitual permanecía en modo seguro, cunha diferenza entre os bloques
agardados e os comunicados polo DataNode. Non se forzou a súa saída nin se
borraron datos; esa incidencia queda pendente de revisión separada.

---

## requisitos

- windows 10/11, linux ou macOS
- docker compose v2 
- recomendado: 16 gb ram mínimo (ideal 32 gb)
- espazo en disco: o uso de volumes persistentes (hdfs/kafka/seaweedfs) pode medrar rapidamente

Os servizos con imaxes personalizadas `adbgonzalez/*` están configurados con `platform: linux/amd64`. Nos equipos ARM64, incluídos os Mac con Apple Silicon, o contorno de contedores debe permitir executar AMD64 mediante emulación, que pode reducir o rendemento. Rosetta é unha opción en determinados contornos de macOS; o atributo `platform` selecciona a arquitectura, pero non activa nin configura a emulación.

Os scripts `.ps1` requiren PowerShell, tamén en Linux e macOS.

---

## composición modular do clúster

O proxecto está dividido en varios ficheiros compose, para activar só o que se precisa:

- `compose.base.yml` -> clúster base (hdfs + yarn + spark + jupyter + history server)
- `compose.kafka.yml` -> kafka + kafka ui (redpanda console)
- `compose.seaweedfs.yml` -> seaweedfs (s3)
- `compose.nifi.yml` -> apache nifi (depende de seaweedfs e namenode)
- `compose.superset.yml` -> superset + postgres + redis
- `compose.airflow.yml` -> airflow + postgres (orquestración local; integra co clúster base)


---

## estrutura do repositorio

```
.
+-- compose.base.yml
+-- compose.airflow.yml
+-- compose.hadoop.yml
+-- compose.kafka.yml
+-- compose.seaweedfs.yml
+-- compose.nifi.yml
+-- compose.superset.yml
¦
+-- conf/                 # configuración xml de hadoop (core/hdfs/yarn/mapred)
+-- spark-conf/           # configuración específica de spark (spark-defaults.conf)
¦
+-- airflow/
¦   +-- dags/             # dags de airflow (bind mount)
¦   +-- config/           # configuración local de airflow (bind mount)
¦   +-- plugins/          # plugins personalizados de airflow (bind mount)
¦   +-- requirements.txt  # providers/paquetes Python adicionais para a imaxe de Airflow
¦   +-- Dockerfile        # build da imaxe personalizada de Airflow
¦
+-- jupyter/              # dockerfile + dependencias do contedor jupyterlab
+-- kafka/                # recursos e configuración asociados a kafka (se aplica)
¦
+-- jars/                 # jars auxiliares para Spark (volume opcional)
+-- scripts/              # scripts .ps1/.sh para arranque, parada e utilidades
¦   +-- up-base.ps1
¦   +-- init-airflow.ps1
¦   +-- up-airflow.ps1
¦   +-- up-airflow-seaweedfs.ps1
¦   +-- up-kafka.ps1
¦   +-- up-seaweedfs.ps1
¦   +-- up-nifi.ps1
¦   +-- up-all.ps1
¦   +-- down-airflow.ps1
¦   +-- down.ps1
¦   +-- down-v.ps1
¦   +-- down-all.ps1
¦   +-- logs-airflow.ps1
¦   +-- logs-ui.ps1
¦   +-- logs-kafka.ps1
¦   +-- logs-nifi.ps1
¦   +-- logs-notebook.ps1
¦   +-- ps.ps1
¦   +-- prep-exame.ps1
¦   +-- reset-checkpoints.ps1
¦   +-- reset-checkpoints.sh
¦   +-- reset-kafka-topics.ps1
¦   +-- reset-kafka-topics.sh
¦
+-- README.md
```

---

## estrutura de traballo recomendada (alumnado)

Este clúster está pensado para usarse xunto cun repositorio separado de notebooks de Spark.
Para evitar repositorios Git aniñados e facilitar o traballo, **ambos repositorios deben clonarse ao mesmo nivel**, dentro dun cartafol de traballo común.

A estrutura recomendada é a seguinte:
```bash
big-data-lab/ -> cartafol de traballo (non é repositorio git)
+-- big-data-cluster/ -> este repositorio
+-- spark-notebooks/ -> repositorio de notebooks de Spark
```


Importante: **o cartafol dos notebooks debe chamarse exactamente `spark-notebooks`**, xa que o contedor de Jupyter monta ese directorio como volume.

### clonado dos repositorios

```bash
mkdir big-data-lab
cd big-data-lab

git clone https://github.com/adbgonzalez/big-data-cluster big-data-cluster
git clone https://github.com/adbgonzalez/notebooks-spark-26-27 spark-notebooks

```
Se xa tiñas clonado o repositorio de notebooks con outro nome, renómeao a `spark-notebooks` (ou, en macos/linux, crea unha ligazón simbólica: `ln -s notebooks-spark-26-27 spark-notebooks`).

Unha vez clonados os dous repositorios, o clúster arráncase cos scripts de **big-data-cluster/scripts**: os `.ps1` en windows e os `.sh` en macos/linux, tal e como se describe nos apartados seguintes.

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

#### seaweedfs (s3)
```powershell
.\up-seaweedfs.ps1
```

#### nifi (depende de seaweedfs + namenode)
```powershell
.\up-nifi.ps1
.\logs-nifi.ps1
```

#### superset
```powershell
docker compose -f compose.base.yml -f compose.superset.yml up -d
```

#### airflow
Antes do primeiro arranque de Airflow ou cando se modifique `airflow/requirements.txt`, hai que construír a imaxe personalizada:

```powershell
docker build --platform linux/amd64 -t adbgonzalez/airflow:3.1.8 .\airflow
```

O argumento `--platform linux/amd64` constrúe a imaxe para a mesma arquitectura que usa Compose. É necesario indicalo neste comando porque `docker build` non le o atributo `platform` dos ficheiros compose.

Despois:

```powershell
.\init-airflow.ps1   # só a primeira vez / tras reset da BD de airflow
.\up-airflow.ps1     # levanta tamén o clúster base
.\logs-airflow.ps1
```

Se ademais queres levantar dependencias frecuentes para os DAGs:

```powershell
docker compose -f ..\compose.base.yml -f ..\compose.seaweedfs.yml -f ..\compose.airflow.yml up -d
.\up-kafka.ps1   # se tamén precisas kafka
```

`init-airflow.ps1` executa as migracións da base de datos de Airflow.  
`up-airflow.ps1` levanta o clúster base (`namenode`, `datanode`, `yarn`, `history`, `notebook`) xunto con `airflow-db`, `airflow-api-server`, `airflow-scheduler` e `airflow-dag-processor`.
O comando anterior de Docker Compose engade tamén `seaweedfs`, e `up-kafka.ps1` levanta ademais `kafka` e `redpanda-console`.

O stack de Airflow usa un `jwt_secret` compartido entre servizos para que a Execution API interna funcione correctamente en Airflow 3.

A imaxe personalizada de Airflow toma como base `apache/airflow:3.1.8` e instala os providers definidos en `airflow/requirements.txt`.

---

### 3) levantar todo (base + módulos)
```powershell
.\up-all.ps1
```

---

## inicio rápido (macos / linux)

En macos e linux úsanse os scripts `.sh` de `scripts/`. Son equivalentes un a un aos `.ps1` e pódense executar desde calquera directorio:

```bash
./scripts/up-base.sh        # clúster base
./scripts/ps.sh             # contedores activos
./scripts/logs-notebook.sh  # logs de jupyterlab
./scripts/up-kafka.sh       # base + kafka
./scripts/up-all.sh         # base + todos os módulos
./scripts/down.sh           # parar (mantén volumes)
```

Airflow, igual que en windows: `./scripts/init-airflow.sh` a primeira vez e despois `./scripts/up-airflow.sh`. Para construír a imaxe personalizada en apple silicon hai que indicar a plataforma, porque a imaxe de spark da que parte só existe para amd64:

```bash
docker build --platform linux/amd64 -t adbgonzalez/airflow:3.1.8 ./airflow
```

### rancher desktop (macos)

Probado con rancher desktop en apple silicon. Na configuración (preferences) hai que ter:

- **container engine**: `dockerd (moby)`. Con `containerd` non hai `docker compose`.
- **virtual machine → emulation**: `VZ` con **rosetta** activado. É o que permite executar as imaxes amd64; con qemu a emulación é moito máis lenta.
- **virtual machine → volumes**: `virtiofs`.
- **virtual machine → hardware**: polo menos 12 gb de memoria e 4 cpus. O valor por defecto non chega para o clúster base.

Rancher desktop engade `~/.rd/bin` ao PATH (`docker`, `docker compose`); se nunha terminal non se atopa `docker`, abre unha nova ou engade esa ruta ao `~/.zshrc`.

Con docker desktop o equivalente é activar rosetta en settings → general e asignar memoria de abondo á vm en settings → resources.

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

### seaweedfs
| servizo | url | descrición |
|--------|-----|------------|
| consola web | http://localhost:9001 | panel de administración |
| api s3 | http://localhost:9002 | endpoint s3 (porto 8333 interno) |

As credenciais S3 configúranse con `S3_ACCESS_KEY` e `S3_SECRET_KEY`. Os valores por defecto están definidos en `compose.seaweedfs.yml`.

### nifi
| servizo | url | descrición |
|--------|-----|------------|
| nifi (https) | https://localhost:9091 | ui web |

credenciais por defecto:
- user: `admin`
- pass: `Admin.BDA123!`

(pódense cambiar con `NIFI_USER` e `NIFI_PASS`)

### superset
| servizo | url | descrición |
|--------|-----|------------|
| superset | http://localhost:8090 | bi e dashboards |

credenciais por defecto:
- user: `admin`
- pass: `admin`

### airflow
| servizo | url | descrición |
|--------|-----|------------|
| airflow ui/api | http://localhost:8091 | orquestración local e execución de DAGs |

acceso:
- sen login (configurado para contorno local de prácticas)

nota:
- inclúe un DAG mínimo de proba en `airflow/dags/hello_airflow.py`
- pódense engadir providers de Airflow modificando `airflow/requirements.txt` e reconstruíndo a imaxe `adbgonzalez/airflow:3.1.8`

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

### parar e borrar volumes (elimina datos persistentes)
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
