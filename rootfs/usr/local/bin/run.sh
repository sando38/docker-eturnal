#!/bin/sh

# Install acme.sh script: https://github.com/acmesh-official/acme.sh
wget -O -  https://get.acme.sh | sh -s \
       email=${ACME_EMAIL:-admin@example.com} \
       --no-cron

s6_cron='/etc/s6.d/cron/run'
acme_sh="$(find $HOME -type f -executable -name acme.sh)"

# Apply environment variables settings
sed -i -e "s|<ACME_CRON_PERIOD>|${ACME_CRON_PERIOD:-60d}|g" "$s6_cron" \
       -e "s|<ACME_DOMAIN>|${ACME_DOMAIN:-turn.exaple.com}|g" "$s6_cron" \
       -e "s|<ACME_SH>|$acme_sh|g" "$s6_cron"

# Generate initial TLS certificatets
cron-acme.sh

# finalize minimal configuration file:
## enable `mod_stats_prometheus`
if [ ${MOD_STATS_PROMETHEUS_ENABLE:-false} = 'true' ]
then cat >> $HOME/etc/eturnal.yml <<-EOF
    mod_stats_prometheus:
      ip: ${MOD_STATS_PROMETHEUS_IP:-any}
      port: ${MOD_PROMETHEUS_PORT:-8081}
      tls: ${MOD_PROMETHEUS_TLS:-false}
      vm_metrics: ${MOD_PROMETHEUS_VM_METRICS:-true}

EOF
fi

## adjust default blacklist
if [ ${BLACKLIST:-default} = 'recommended' ]
then cat >> $HOME/etc/eturnal.yml <<-EOF
  blacklist:
    - "127.0.0.0/8"
    - "::1"
    - recommended

EOF
fi

## adjust default listener ports and log level
cat >> $HOME/etc/eturnal.yml <<-EOF
  listen:
    -
      ip: "::"
      port: ${LISTEN_UDP_PORT:-3478}
      transport: udp
    -
      ip: "::"
      port: ${LISTEN_TCP_TLS_PORT:-3478}
      transport: auto

  tls_crt_file: $(find $HOME -name fullchain.pem)
  tls_key_file: $(find $HOME -name key.pem)

  log_level: ${LOG_LEVEL:-info}

  strict_expiry: ${CREDENTIALS_STRICT_EXPIRY:-false}
EOF

## realm: https://eturnal.net/documentation/#realm
if [ ! -z ${REALM-} ]
then cat >> $HOME/etc/eturnal.yml <<-EOF
  realm: ${REALM-}

EOF
fi

# Run processes
exec /bin/s6-svscan /etc/s6.d
