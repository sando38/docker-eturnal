# Inofficial [eturnal](https://eturnal.net) container image

This variant includes the `acme.sh` script ([source][https://github.com/acmesh-official/acme.sh]).
It works like the [standalone eturnal container image](https://github.com/processone/eturnal/tree/master/docker-k8s),
but contains a cron job for creating/renewing TLS certificates.

## Configuration

It can be customized with the following environment variables.

### ACME options

| Name  | Description  |  Default value | Additional notes  |
| ------------ | ------------ | ------------ | ------------ |
| `ACME_EMAIL`  | a valid email address  | `admin@example.com` |   |
| `ACME_DOMAIN`  | only one domain supported  | `turn.example.com` |   |
| `ACME_KEY_SIZE`  | [key lengths](https://github.com/acmesh-official/acme.sh#10-issue-ecc-certificates)  | `4096` |   |
| `ACME_SH_UPGRADE`  | defines, whether the cron job also upgrades `acme.sh`  | `true` |  |
| `ACME_CHALLENGE`  | either `http` (default) or `https`. | `http` | This must not interfere with the `LISTEN_TCP_TLS_PORT` (default: `3478`) |
| `ACME_CRON_PERIOD`  | defines renewal interval  | `60d` |   |

### Listener options

| Name  | Description  |  Default value | Additional notes  |
| ------------ | ------------ | ------------ | ------------ |
| `LISTEN_UDP_PORT`  | Defines the UDP listener [here](https://eturnal.net/documentation/#listen)  | `3478` |  |
| `LISTEN_TCP_TLS_PORT`  | Defines the multiplex TCP/TLS listener [here](https://eturnal.net/documentation/#listen)  | `3478` | This may be used for port `443` |
| `ETURNAL_RELAY_IPV4_ADDR`  | More infos [here](https://eturnal.net/documentation/#relay_ipv4_addr)  |  | no default, auto-detected if possible |
| `ETURNAL_RELAY_IPV6_ADDR`  | More infos [here](https://eturnal.net/documentation/#relay_ipv6_addr)  |  | no default, auto-detected if possible |
| `ETURNAL_RELAY_MAX_PORT`  | More infos [here](https://eturnal.net/documentation/#relay_max_port)  | `65535` |  |
| `ETURNAL_RELAY_MIN_PORT`  | More infos [here](https://eturnal.net/documentation/#relay_min_port)  | `49152` |  |
| `ETURNAL_SECRET`  | More infos [here](https://eturnal.net/documentation/#secret)  |  | no default, auto-generated |

### module `mod_stats_prometheus``

| Name  | Description  |  Default value | Additional notes  |
| ------------ | ------------ | ------------ | ------------ |
| `MOD_STATS_PROMETHEUS_ENABLE`  | enable or disable the module  | `false` |  |
| `MOD_STATS_PROMETHEUS_IP`  | More infos [here](https://eturnal.net/documentation/#mod_stats_prometheus)  | `any` |  |
| `MOD_PROMETHEUS_PORT`  | see above  | `8081` |  |
| `MOD_PROMETHEUS_TLS`  | see above  | `false` |  |
| `MOD_PROMETHEUS_VM_METRICS`  | see above  | `true` |  |

### additional configuration options

| Name  | Description  |  Default value | Additional notes  |
| ------------ | ------------ | ------------ | ------------ |
| `BLACKLIST`  | Options: `default` or `recommended`, more infos [here](https://eturnal.net/documentation/#blacklist)  | `default` |  |
| `LOG_LEVEL`  | Sets [log level](https://eturnal.net/documentation/#log_level)  | `info` |  |
| `CREDENTIALS_STRICT_EXPIRY`  | More infos [here](https://eturnal.net/documentation/#strict_expiry)  | `info` |  |
| `STUN_SERVICE`  | External IP address lookup, more infos [here](https://github.com/processone/eturnal/tree/master/docker-k8s#general-hints))  | `stun.conversations.im 3478` | Set to `false` to disable, or us another STUN service |
| `REALM`  | This option defines the [realm](https://eturnal.net/documentation/#realm)  | | no default |

### Limitations

* The image does currently **not** support running with the option `--read-only`.
* No support for providing a custom `eturnal.yml` configuration file.
* No support for providing custom TLS certificates.
* Only *one* `ACME_DOMAIN` can be defined.
* Only the two listeners (`udp` & `tcp`/`tls` in mode `auto`) are defined.

## Examples

The image works with `docker` or `podman`.

```
docker run -d --rm \
    --name eturnal \
    --cap-drop=ALL \
    --cap-add=NET_BIND_SERVICE \
    -p 80:80/udp \
    -e LISTEN_UDP_PORT=80 \
    -p 443:443 \
    -e LISTEN_TCP_TLS_PORT=443 \
    -p 50000-50500:50000-50500/udp \
    -e ETURNAL_RELAY_MIN_PORT=50000 \
    -e ETURNAL_RELAY_MAX_PORT=50500 \
    -e ETURNAL_SECRET=super-secret-password \
    -e ACME_CHALLENGE=http \
    -e ACME_EMAIL=admin@example.com \
    -e ACME_DOMAIN=turn.example.com \
  ghcr.io/sando38/docker-eturnal
```

