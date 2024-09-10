job "sentry-self-hosted" {
  datacenters = ["dc1"]

  group "sentry" {
    network {
      port "smtp" { to = 25 }
      port "redis" { to = 6379 }
      port "postgres" { to = 5432 }
      port "kafka1" { 
        to = 29092
        }
              port "kafka2" { 
        to = 29093
        }
      port "clickhouse" { to = 8123 }
      port "web" { to = 9000 }
      port "nginx" { to = 80 }
      port "memcached" { to = 11211 }
    }


    restart {
      interval = "2m"
      attempts = 6
      delay    = "15s"
      mode     = "delay"
    }

    reschedule {
      delay          = "30s"
      delay_function = "exponential"
      max_delay      = "10m"
      unlimited      = true
    }
    
    task "smtp" {
      driver = "podman"
      config {
        image   = "tianon/exim4"
        volumes = [
          "/var/lib/sentry/sentry-smtp:/var/spool/exim4",
          "/var/lib/sentry/sentry-smtp-log:/var/log/exim4"
        ]
        hostname = ""
      }
    }
    
    task "memcached" {
      driver = "podman"
      config {
        image   = "memcached:1.6.26-alpine"
        args = ["-I", "1M"]
      }
      service {
        provider = "nomad"
        name     = "memcached"
        port     = "memcached"
        check {
          name     = "memcached_health"
          type     = "tcp"
          interval = "30s"
          timeout  = "1m30s"
        }
      }
    }
    
    task "redis" {
      driver = "podman"
      config {
        image   = "redis:6.2.14-alpine"
        volumes = ["/var/lib/sentry/sentry-redis:/data"]
      }
      service {
        provider = "nomad"
        name     = "redis"
        port     = "redis"
        check {
          name     = "redis_health"
          type     = "tcp"
          interval = "30s"
          timeout  = "1m30s"
        }
      }
    }

    task "postgres" {
      driver = "podman"
      config {
        image   = "postgres:14.11"
        command = "postgres"
        args = [ "-c", "max_connections=100"]
        volumes = ["/var/lib/sentry/sentry-postgres:/var/lib/postgresql/data"]
      }
      env {
        POSTGRES_HOST_AUTH_METHOD = "trust"
        POSTGRES_USER             = "postgres"
      }
      service {
        provider = "nomad"
        name     = "postgres"
        port     = "postgres"
        check {
          name     = "postgres_health"
          type     = "tcp"
          interval = "30s"
          timeout  = "1m30s"
        }
      }
    }

    task "kafka" {
      driver = "podman"
      config {
        image = "confluentinc/cp-kafka:7.6.1"
        volumes = [
          "/var/lib/sentry/sentry-kafka:/var/lib/kafka/data",
          "/var/lib/sentry/sentry-kafka-log:/var/lib/kafka/log",
          "/var/lib/sentry/sentry-secrets:/etc/kafka/secrets"
        ]
      }
      env {
        KAFKA_PROCESS_ROLES                   = "broker,controller"
        KAFKA_CONTROLLER_QUORUM_VOTERS        = "1001@127.0.0.1:29093"
        KAFKA_CONTROLLER_LISTENER_NAMES       = "CONTROLLER"
        KAFKA_NODE_ID                         = "1001"
        CLUSTER_ID                            = "MkU3OEVBNTcwNTJENDM2Qk"
        KAFKA_LISTENERS                       = "PLAINTEXT://0.0.0.0:29092,INTERNAL://0.0.0.0:9093,EXTERNAL://0.0.0.0:9092,CONTROLLER://0.0.0.0:29093"
        KAFKA_ADVERTISED_LISTENERS            = "PLAINTEXT://127.0.0.1:29092,INTERNAL://kafka:9093,EXTERNAL://kafka:9092"
        KAFKA_LISTENER_SECURITY_PROTOCOL_MAP  = "PLAINTEXT:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT"
        KAFKA_INTER_BROKER_LISTENER_NAME      = "PLAINTEXT"
        KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR= "1"
        KAFKA_OFFSETS_TOPIC_NUM_PARTITIONS    = "1"
        KAFKA_LOG_RETENTION_HOURS             = "24"
        KAFKA_MESSAGE_MAX_BYTES               = "50000000"
        KAFKA_MAX_REQUEST_SIZE                = "50000000"
        CONFLUENT_SUPPORT_METRICS_ENABLE      = "false"
        KAFKA_LOG4J_LOGGERS                   = "kafka.cluster=WARN,kafka.controller=WARN,kafka.coordinator=WARN,kafka.log=WARN,kafka.server=WARN,state.change.logger=WARN"
        KAFKA_LOG4J_ROOT_LOGLEVEL             = "WARN"
        KAFKA_TOOLS_LOG4J_LOGLEVEL            = "WARN"
      }
      service {
        provider = "nomad"
        name     = "kafka"
        port     = "kafka1"
        check {
          name     = "kafka_health"
          type     = "tcp"
          interval = "30s"
          timeout  = "1m30s"
        }
      }
    }

    task "clickhouse" {
      driver = "podman"
      config {
        image = "altinity/clickhouse-server:23.8.11.29.altinitystable"
        volumes = [
          "/var/lib/sentry/sentry-clickhouse:/var/lib/clickhouse",
          "/var/lib/sentry/sentry-clickhouse-log:/var/log/clickhouse-server",
          "/home/ttys3/repo/pter/self-hosted/clickhouse/config.xml:/etc/clickhouse-server/config.d/sentry.xml:ro"
        ]
      }
      env {
        MAX_MEMORY_USAGE_RATIO = "0.3"
      }
      service {
        provider = "nomad"
        name     = "clickhouse"
        port     = "clickhouse"
        check {
          name     = "clickhouse_health"
          type     = "tcp"
          interval = "30s"
          timeout  = "1m30s"
        }
      }
    }

    task "web" {
      driver = "podman"
      config {
       image = "docker.io/80x86/sentry-self-hosted-local"
        entrypoint   = ["/etc/sentry/entrypoint.sh"]
        args      = ["run", "web"]
        volumes      = [
            "/var/lib/sentry/sentry-data:/data", 
        "/home/ttys3/repo/pter/self-hosted/sentry:/etc/sentry", 
        "/var/lib/sentry/geoip:/geoip:ro", 
        ]
      }
      env {
        PYTHONUSERBASE                        = "/data/custom-packages"
        SENTRY_CONF                           = "/etc/sentry"
        SNUBA                                 = "http://snuba-api:1218"
        VROOM                                 = "http://vroom:8085"
        DEFAULT_CA_BUNDLE                     = "/etc/ssl/certs/ca-certificates.crt"
        REQUESTS_CA_BUNDLE                    = "/etc/ssl/certs/ca-certificates.crt"
        GRPC_DEFAULT_SSL_ROOTS_FILE_PATH_ENV_VAR = "/etc/ssl/certs/ca-certificates.crt"
        SENTRY_EVENT_RETENTION_DAYS           = 90
      }
      service {
        provider = "nomad"
        name     = "web"
        port     = "web"
        check {
          name     = "web_health"
          type     = "tcp"
          interval = "30s"
          timeout  = "1m30s"
        }
      }
    }

    task "nginx" {
      driver = "podman"
      config {
        image   = "nginx:1.25.4-alpine"
        volumes = [
          "/home/ttys3/repo/pter/self-hosted/nginx:/etc/nginx:ro",
          "/var/lib/sentry/sentry-nginx-cache:/var/cache/nginx"
        ]
      }
      service {
        provider = "nomad"
        name     = "nginx"
        port     = "nginx"
        check {
          name     = "nginx_health"
          type     = "tcp"
          interval = "30s"
          timeout  = "1m30s"
        }
      }
    }


# Define volumes as external or local based on Nomad volume options.
volume "sentry-data" {
  source = "sentry-data"
}
volume "sentry-postgres" {
  source = "sentry-postgres"
}
volume "sentry-redis" {
  source = "sentry-redis"
}
volume "sentry-kafka" {
  source = "sentry-kafka"
}
volume "sentry-clickhouse" {
  source = "sentry-clickhouse"
}
volume "sentry-symbolicator" {
  source = "sentry-symbolicator"
}
volume "sentry-vroom" {
    source = "sentry-vroom"
}
volume "sentry-secrets" {
    source = "sentry-secrets"
}
volume "sentry-smtp" {
    source = "sentry-smtp"
}
volume "sentry-nginx-cache" {
    source = "sentry-nginx-cache"
}
volume "sentry-kafka-log" {
    source = "sentry-kafka-log"
}
volume "sentry-smtp-log" {
    source = "sentry-smtp-log"
}
volume "sentry-clickhouse-log" {
    source = "sentry-clickhouse-log"
}

/*
podman volume create sentry-data
podman volume create sentry-postgres
podman volume create sentry-redis
podman volume create sentry-kafka
podman volume create sentry-clickhouse
podman volume create sentry-symbolicator
podman volume create sentry-vroom
podman volume create sentry-secrets
podman volume create sentry-smtp
podman volume create sentry-nginx-cache
podman volume create sentry-kafka-log
podman volume create sentry-smtp-log
podman volume create sentry-clickhouse-log
*/

  } // end group
}
