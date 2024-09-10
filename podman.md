Understood. To avoid this prompt in the future, use one of these flags:

  --report-self-hosted-issues
  --no-report-self-hosted-issues

or set the REPORT_SELF_HOSTED_ISSUES environment variable:

  REPORT_SELF_HOSTED_ISSUES=1 to send data
  REPORT_SELF_HOSTED_ISSUES=0 to not send data


podman-compose

sed -i 's|--ansi never|--no-ansi|g' `rg -l 'ansi never'`

sd -s 'docker volume create --name=' 'docker volume create ' `rg -l 'docker volume create'`


docker.io/getsentry/relay:24.8.0


               "Ulimits": [
                    {
                         "Name": "RLIMIT_NOFILE",
                         "Soft": 262144,
                         "Hard": 262144
                    },
                    {
                         "Name": "RLIMIT_NPROC",
                         "Soft": 102403,
                         "Hard": 204806
                    }
               ],


```
mkdir -p /var/lib/sentry/sentry-smtp 
mkdir -p /var/lib/sentry/sentry-smtp-log
mkdir /var/lib/sentry/sentry-redis
mkdir /var/lib/sentry/sentry-postgres
mkdir /var/lib/sentry/sentry-kafka
mkdir /var/lib/sentry/sentry-kafka-log
mkdir /var/lib/sentry/sentry-secrets
mkdir /var/lib/sentry/sentry-clickhouse
mkdir /var/lib/sentry/sentry-clickhouse-log
mkdir /var/lib/sentry/sentry-data
mkdir /var/lib/sentry/geoip
mkdir /var/lib/sentry/sentry-nginx-cache
```


$HOME/.config/containers/registries.conf.d/001-my-shortnames.conf