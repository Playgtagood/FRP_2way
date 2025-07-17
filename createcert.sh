#!/bin/bash
Address=($(ip a | grep inet | awk '{gsub(/\/.*/,"",$2);print $2}'))
for i in ${!Address[@]};do
		                echo "$i ${Address[$i]}"
			        done
				echo "Please Choose The Number Of Your IP:"
				read index
				if [[ "$index" =~ ^[0-9]+$ ]] && (( index >= 0 && index < ${#Address[@]} )); then
					        ip=${Address[$index]}
						echo $ip
					else
						echo "Fail!"
				fi
mkdir ca
cat > ca/my-openssl.cnf << EOF
[ ca ]
default_ca = CA_default
[ CA_default ]
x509_extensions = usr_cert
[ req ]
default_bits        = 2048
default_md          = sha256
default_keyfile     = privkey.pem
distinguished_name  = req_distinguished_name
attributes          = req_attributes
x509_extensions     = v3_ca
string_mask         = utf8only
[ req_distinguished_name ]
[ req_attributes ]
[ usr_cert ]
basicConstraints       = CA:FALSE
nsComment              = "OpenSSL Generated Certificate"
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
[ v3_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = CA:true
EOF
openssl genrsa -out ca/ca.key 2048
openssl req -x509 -new -nodes -key ca/ca.key -subj "/CN=example.ca.com" -days 5000 -out ca/ca.crt
echo "CA Certificate Has Been Created"

openssl genrsa -out ca/server.key 2048

openssl req -new -sha256 -key ca/server.key \
	    -subj "/C=XX/ST=DEFAULT/L=DEFAULT/O=DEFAULT/CN=server.com" \
	        -reqexts SAN \
		    -config <(cat ca/my-openssl.cnf <(printf "\n[SAN]\nsubjectAltName=DNS:localhost,IP:$ip,DNS:example.server.com")) \
		        -out ca/server.csr

openssl x509 -req -days 365 -sha256 \
	-in ca/server.csr -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial \
	-extfile <(printf "subjectAltName=DNS:localhost,IP:$ip,DNS:example.server.com") \
	-out ca/server.crt

openssl genrsa -out ca/client.key 2048
openssl req -new -sha256 -key ca/client.key \
	    -subj "/C=XX/ST=DEFAULT/L=DEFAULT/O=DEFAULT/CN=client.com" \
	        -reqexts SAN \
		    -config <(cat ca/my-openssl.cnf <(printf "\n[SAN]\nsubjectAltName=DNS:client.com,DNS:example.client.com")) \
		        -out ca/client.csr

openssl x509 -req -days 365 -sha256 \
    -in ca/client.csr -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial \
	-extfile <(printf "subjectAltName=DNS:client.com,DNS:example.client.com") \
	-out ca/client.crt
