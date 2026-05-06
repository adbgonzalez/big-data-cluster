docker compose -f ..\compose.base.yml -f ..\compose.superset.yml -f ..\compose.postgres.yml up -d superset-db superset-redis superset postgres-serving
