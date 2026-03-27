docker compose -f ..\compose.base.yml -f ..\compose.airflow.yml logs -f airflow-api-server airflow-scheduler airflow-dag-processor
