Only for local TLS proxy tests. This private key is public test data; never use it outside tests.

The certificate is trusted explicitly by the test client, so production certificate validation is unchanged. Apple requires a short server certificate lifetime. Regenerate this fixture before its October 2027 expiry:

```sh
openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 365 \
  -subj /CN=localhost -addext subjectAltName=DNS:localhost \
  -addext extendedKeyUsage=serverAuth \
  -keyout test/fixtures/proxy/key.pem -out test/fixtures/proxy/cert.pem
```
