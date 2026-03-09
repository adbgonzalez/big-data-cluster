# Instrucións para iniciar o contorno de Big Data

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```
Na carpeta `recursos_exame` da unidade D: hai dous ficheiros importantes:

- `bda-core-images.tar` → imaxes Docker necesarias
- `ivy2-offline.tar` → caché de dependencias de Spark

Todos os comandos deben executarse en **PowerShell** na carpeta do proxecto.

---

# 0) Poñer Docker en modo Linux



abrir **Docker Desktop** → icono de Docker na bandexa → seleccionar **Switch to Linux containers**.

---

# 1) cargar as imaxes Docker do cluster

Executar:

```powershell
docker load -i .\bda-core-images.tar
```

Isto cargará as imaxes necesarias do cluster sen descargalas de Internet (aproximadamente 1:30).

Pódese comprobar con:

```powershell
docker images
```

---

# 2) iniciar o cluster

Executar:

```powershell
docker compose -f compose.base.yml -f compose.kafka.yml up -d
```

Esperar uns segundos ata que arranquen os servizos.

Para comprobar:

```powershell
docker ps
```

Debe aparecer, entre outros:

- `spark-notebook`
- `namenode`
- `datanode`
- `resourcemanager`
- `kafka`

---

# 3) cargar as dependencias de Spark (caché Ivy)

Executar:

```powershell
docker cp .\ivy2-offline.tar spark-notebook:/tmp/ivy2-offline.tar
```

Despois:

```powershell
docker exec spark-notebook bash -lc "tar -C /home/hadoop -xf /tmp/ivy2-offline.tar && chown -R 1000:1000 /home/hadoop/.ivy2"
```

Isto instala localmente todas as librarías necesarias para Spark (Delta, Kafka, etc.) e evita que Spark teña que descargalas.

---

# 4) comprobar que Spark funciona correctamente (proba rápida)

Executar:

```powershell
docker exec -u 1000:1000 spark-notebook bash -lc "spark-shell -e 'println(\"ivy ok\")'"
```

Se aparece algo como:

```
already retrieved
```

e **non aparecen liñas de `downloading https://...`**, entón está correcto.

---

# 5) abrir o notebook

Abrir no navegador:

```
http://localhost:8888
```

JupyterLab abrirase directamente (sen token nin contrasinal).

---

# 6) parar o cluster ao rematar

Executar:

```powershell
docker compose -f compose.base.yml -f compose.kafka.yml stop
```

⚠️ **Non executar `docker compose down`**, porque podería borrar contedores e obrigar a repetir o paso 3.

---

# 7) comandos útiles (se algo falla)

Ver contedores activos:

```powershell
docker ps
```

Ver logs do notebook:

```powershell
docker logs spark-notebook --tail 50
```

Se Spark intenta descargar dependencias, repetir o **paso 3**.