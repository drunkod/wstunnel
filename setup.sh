#!/bin/bash
set -e

# --- Configuration ---
CERT_DIR="certs"
CONFIG_DIR="config"
SERVER_TEMPLATE="$CONFIG_DIR/server-template.json"
CLIENT_TEMPLATE="$CONFIG_DIR/client-template.json"
FINAL_SERVER_CONFIG="$CONFIG_DIR/server.json"
FINAL_CLIENT_CONFIG="$CONFIG_DIR/client.json"

# --- Check for dependencies ---
if ! command -v openssl &> /dev/null; then
    echo "Error: openssl could not be found. Please install it."
    exit 1
fi

# --- Create directories ---
mkdir -p "$CERT_DIR"
mkdir -p "$CONFIG_DIR"

# --- 1. Generate Self-Signed Certificate ---
echo "Generating self-signed certificate..."
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$CERT_DIR/key.pem" \
  -out "$CERT_DIR/cert.pem" \
  -subj "/CN=localhost"

echo "Certificate and key saved in ./$CERT_DIR/"

# --- 2. Calculate Certificate Hash ---
echo "Calculating public key hash for client pinning..."
CERT_HASH=$(openssl x509 -in "$CERT_DIR/cert.pem" -pubkey -noout | \
            openssl pkey -pubin -outform der | \
            openssl dgst -sha256 -binary | \
            openssl base64)

echo "Public Key Hash: $CERT_HASH"

# --- 3. Generate Final Config Files ---
echo "Generating final config files from templates..."
# The server config template is already correct, so we just copy it.
cp "$SERVER_TEMPLATE" "$FINAL_SERVER_CONFIG"

# Replace the hash placeholder in the client config.
sed "s|__CERT_HASH__|$CERT_HASH|g" "$CLIENT_TEMPLATE" > "$FINAL_CLIENT_CONFIG"

echo "Setup complete! You can now run 'docker-compose up'."