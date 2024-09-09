echo "${_group}Creating volumes for persistent storage ..."

echo "Created $(docker volume create sentry-clickhouse)."
echo "Created $(docker volume create sentry-data)."
echo "Created $(docker volume create sentry-kafka)."
echo "Created $(docker volume create sentry-postgres)."
echo "Created $(docker volume create sentry-redis)."
echo "Created $(docker volume create sentry-symbolicator)."

echo "${_endgroup}"
