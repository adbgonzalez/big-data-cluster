FROM adbgonzalez/spark:4.1.1-py312

USER root

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Crear espazo de traballo accesible para o usuario hadoop
RUN mkdir -p /home/hadoop/work && chown -R hadoop:hadoop /home/hadoop

USER hadoop
WORKDIR /home/hadoop/work
