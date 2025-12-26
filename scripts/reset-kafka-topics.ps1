$topics = @("entrada", "salida", "test-notebook")

foreach ($t in $topics) {
  Write-Host "Borrando topic $t ..."
  docker exec -it kafka bash -lc "/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --delete --topic $t" | Out-Host
}
