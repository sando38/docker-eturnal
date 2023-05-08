#!/bin/sh

email="${ACME_EMAIL:-admin@example.com}"
domain="${ACME_DOMAIN:-turn.example.com}"
cert_dir="$HOME/tls"
key_size="${ACME_KEY_SIZE:-4096}"
acme_sh="$HOME/.acme.sh/acme.sh"

create_tls_certs()
{
        local email="$1"
        local domain="$2"
        local cert_dir="$3"
        local key_size="$4"

        echo "create/ renew certificates for domain $domain ..."
        $acme_sh --issue --"$challenge" \
                --keylength "$key_size" \
                --always-force-new-domain-key \
                -d $domain \
                --server zerossl \
                --key-file $cert_dir/key.pem \
                --ca-file $cert_dir/ca.pem \
                --cert-file $cert_dir/crt.pem \
                --fullchain-file $cert_dir/fullchain.pem \
                --reloadcmd 'eturnalctl reload' \
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
fi

create_tls_certs "$email" "$domain" "$cert_dir"
