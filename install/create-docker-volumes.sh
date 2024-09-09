echo "${_group}Creating volumes for persistent storage ..."

echo "Created $(docker volume create --ignore sentry-clickhouse)."
echo "Created $(docker volume create --ignore sentry-data)."
echo "Created $(docker volume create --ignore sentry-kafka)."
echo "Created $(docker volume create --ignore sentry-postgres)."
echo "Created $(docker volume create --ignore sentry-redis)."
echo "Created $(docker volume create --ignore sentry-symbolicator)."

echo "${_endgroup}"
