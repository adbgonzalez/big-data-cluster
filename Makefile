COMPOSE=docker compose

BASE=-f compose.base.yml
KAFKA=-f compose.kafka.yml
MINIO=-f compose.minio.yml
NIFI=-f compose.nifi.yml
ZEP=-f compose.zeppelin.yml

.PHONY: help up-base up-kafka up-minio up-nifi up-zeppelin up-all down down-v ps logs-kafka logs-ui logs-nifi logs-notebook reset-checkpoints reset-kafka-topics

help:
	@echo "Comandos dispoñibles:"
	@echo "  make up-base        -> core (hdfs/yarn/spark-history/notebook)"
	@echo "  make up-kafka       -> base + kafka (+ kafka ui se vai en compose.kafka.yml)"
	@echo "  make up-minio       -> base + minio"
	@echo "  make up-nifi        -> base + minio + nifi"
	@echo "  make up-zeppelin    -> base + zeppelin"
	@echo "  make up-all         -> base + kafka + minio + nifi + zeppelin"
	@echo "  make down           -> para contedores (mantén volumes)"
	@echo "  make down-v         -> para e elimina volumes (reset total)"
	@echo "  make ps             -> estado"
	@echo "  make logs-kafka     -> logs kafka"
	@echo "  make logs-ui        -> logs kafka-ui"
	@echo "  make logs-nifi      -> logs nifi"
	@echo "  make logs-notebook  -> logs notebook"
	@echo "  make reset-checkpoints -> borra checkpoints locais (seguro)"
	@echo "  make reset-kafka-topics -> borra topics de prácticas (coidado)"

up-base:
	$(COMPOSE) $(BASE) up -d

up-kafka:
	$(COMPOSE) $(BASE) $(KAFKA) up -d

up-minio:
	$(COMPOSE) $(BASE) $(MINIO) up -d

up-nifi:
	$(COMPOSE) $(BASE) $(MINIO) $(NIFI) up -d

up-zeppelin:
	$(COMPOSE) $(BASE) $(ZEP) up -d

up-all:
	$(COMPOSE) $(BASE) $(KAFKA) $(MINIO) $(NIFI) $(ZEP) up -d

down:
	$(COMPOSE) $(BASE) down

down-v:
	$(COMPOSE) $(BASE) down -v

ps:
	$(COMPOSE) $(BASE) ps

logs-kafka:
	$(COMPOSE) $(BASE) $(KAFKA) logs -f kafka

logs-ui:
	$(COMPOSE) $(BASE) $(KAFKA) logs -f kafka-ui

logs-nifi:
	$(COMPOSE) $(BASE) $(MINIO) $(NIFI) logs -f nifi

logs-notebook:
	$(COMPOSE) $(BASE) logs -f spark-notebook

reset-checkpoints:
	@bash ./scripts/reset-checkpoints.sh

reset-kafka-topics:
	@bash ./scripts/reset-kafka-topics.sh
