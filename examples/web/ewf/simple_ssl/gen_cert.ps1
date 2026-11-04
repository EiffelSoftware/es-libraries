# Generate a self-signed certificate (ca.crt) and its private key (ca.key)
# for the simple_ssl example (see secure_certificate* in simple.ini).
#
# Usage: .\gen_cert.ps1 [-OutDir <dir>] [-CN <name>] [-Days <n>] [-Bits <n>] [-OpenSSL <path>]

param(
	[string]$OutDir = $PSScriptRoot,
	[string]$CN = "localhost",
	[int]$Days = 825,
	[int]$Bits = 2048,
	[string]$OpenSSL = "openssl"
)

$ErrorActionPreference = "Stop"

$Crt = Join-Path $OutDir "ca.crt"
$Key = Join-Path $OutDir "ca.key"

$San = "DNS:localhost, IP:127.0.0.1, IP:::1"
if ($CN -ne "localhost") { $San = "DNS:$CN, $San" }

# Use a config file rather than -addext/-subj, so it also works with LibreSSL.
$Cnf = [System.IO.Path]::GetTempFileName()
try {
	@"
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
subjectAltName       = $San
"@ | Set-Content -Path $Cnf -Encoding Ascii

	& $OpenSSL req -x509 -nodes -newkey "rsa:$Bits" -sha256 -days $Days `
		-config $Cnf -keyout $Key -out $Crt
	if ($LASTEXITCODE -ne 0) { throw "Failed to generate the certificate." }
}
finally {
	Remove-Item -Force -ErrorAction SilentlyContinue $Cnf
}

Write-Host "Generated:"
Write-Host "  certificate: $Crt"
Write-Host "  private key: $Key"
& $OpenSSL x509 -in $Crt -noout -subject -dates
