#!/bin/sh
# Generate a self-signed certificate (ca.crt) and its private key (ca.key)
# for the simple_ssl example (see secure_certificate* in simple.ini).
#
# Usage: ./gen_cert.sh [output_dir]
#   Environment overrides: CN (default: localhost), DAYS (default: 825),
#   BITS (default: 2048), OPENSSL (default: openssl).

set -e

OUT_DIR="${1:-$(dirname "$0")}"
CN="${CN:-localhost}"
DAYS="${DAYS:-825}"
BITS="${BITS:-2048}"
OPENSSL="${OPENSSL:-openssl}"

CRT="$OUT_DIR/ca.crt"
KEY="$OUT_DIR/ca.key"

SAN="DNS:localhost, IP:127.0.0.1, IP:::1"
[ "$CN" = "localhost" ] || SAN="DNS:$CN, $SAN"

# Use a config file rather than -addext/-subj, so it also works with LibreSSL.
CNF=$(mktemp)
trap 'rm -f "$CNF"' EXIT
cat > "$CNF" <<EOF
[ req ]
distinguished_name = dn
x509_extensions    = v3_ext
prompt             = no

[ dn ]
CN = $CN
O  = EiffelWeb simple_ssl example

[ v3_ext ]
basicConstraints     = critical, CA:FALSE
keyUsage             = critical, digitalSignature, keyEncipherment
extendedKeyUsage     = serverAuth
subjectKeyIdentifier = hash
subjectAltName       = $SAN
EOF

"$OPENSSL" req -x509 -nodes -newkey "rsa:$BITS" -sha256 -days "$DAYS" \
	-config "$CNF" -keyout "$KEY" -out "$CRT"
chmod 600 "$KEY"

echo "Generated:"
echo "  certificate: $CRT"
echo "  private key: $KEY"
"$OPENSSL" x509 -in "$CRT" -noout -subject -dates
