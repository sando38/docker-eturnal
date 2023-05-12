#!/bin/sh

email="${ACME_EMAIL:-admin@example.com}"
domain="${ACME_DOMAIN:-turn.example.com}"
cert_dir="$HOME/tls"
key_size="${ACME_KEY_SIZE:-4096}"
acme_sh="$HOME/.acme.sh/acme.sh"
acme_ca="${ACME_CA:-zerossl}"

create_tls_certs()
{
        local email="$1"
        local domain="$2"
        local cert_dir="$3"
        local key_size="$4"
        local dns_provider="${DNS_PROVIDER-}"

        if [ "$acme_challenge" = 'dns' ]
        then acme_sh=""$acme_sh" --issue --"$challenge" "$dns_provider""
        else acme_sh=""$acme_sh" --issue --"$challenge""
        fi

        echo "Create/ renew certificates for domain $domain ..."
        $acme_sh \
                --keylength "$key_size" \
                --always-force-new-domain-key \
                -d $domain \
                --server "$acme_ca" \
                --key-file $cert_dir/key.pem \
                --ca-file $cert_dir/ca.pem \
                --cert-file $cert_dir/crt.pem \
                --fullchain-file $cert_dir/fullchain.pem \
                --reloadcmd '[ ! -f "$HOME/.startup" ] \
                        && eturnalctl reload \
                        || echo "Startup phase, certificates generated!"' \
                --force
}
#.

if [ ${ACME_SH_UPGRADE:-true} = 'true' ]
then "$acme_sh" --upgrade
fi

acme_challenge="${ACME_CHALLENGE:-http}"
if [ "$acme_challenge" = 'http' ]
then challenge='standalone'
elif [ "$acme_challenge" = 'https' ]
then challenge='alpn'
elif [ "$acme_challenge" = 'dns' ]
then challenge='dns'
fi

create_tls_certs "$email" "$domain" "$cert_dir"
