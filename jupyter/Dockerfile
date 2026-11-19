FROM adbgonzalez/spark:4.1.1-py312

USER root

COPY requirements.txt /tmp/requirements.txt
COPY baseline/constraints-existing.txt /tmp/constraints-existing.txt
COPY constraints-gx.txt /tmp/constraints-gx.txt
RUN pip3 install --no-cache-dir \
      --constraint /tmp/constraints-existing.txt \
      --constraint /tmp/constraints-gx.txt \
      -r /tmp/requirements.txt \
 && rm /tmp/requirements.txt /tmp/constraints-existing.txt /tmp/constraints-gx.txt

# Crear espazo de traballo accesible para o usuario hadoop
RUN mkdir -p /home/hadoop/work && chown -R hadoop:hadoop /home/hadoop

USER hadoop
WORKDIR /home/hadoop/work
