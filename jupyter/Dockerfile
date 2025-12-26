FROM adbgonzalez/spark:3.5.7

USER root
RUN apt-get update && apt-get install -y --no-install-recommends python3-pip && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Crear espazo de traballo accesible para o usuario hadoop
RUN mkdir -p /home/hadoop/work && chown -R hadoop:hadoop /home/hadoop

USER hadoop
WORKDIR /home/hadoop/work
