#!/bin/bash

# Script de configuración inicial para el entorno Redmine

echo "🚀 Configurando entorno Redmine con Docker Compose..."

# Crear directorios necesarios
mkdir -p traefik/certs
mkdir -p redmine-config

# Generar certificados autofirmados para localhost
echo "🔐 Generando certificados SSL autofirmados..."
openssl req -x509 -newkey rsa:4096 -keyout traefik/certs/localhost.key -out traefik/certs/localhost.crt -days 365 -nodes -subj '/CN=localhost'

# Crear el archivo de configuración dinámica de Traefik si no existe
if [ ! -f traefik/dynamic.yml ]; then
    echo "📄 Creando configuración dinámica de Traefik..."
    cat > traefik/dynamic.yml << 'EOF'
tls:
  certificates:
    - certFile: /etc/ssl/traefik/localhost.crt
      keyFile: /etc/ssl/traefik/localhost.key
  stores:
    default:
      defaultCertificate:
        certFile: /etc/ssl/traefik/localhost.crt
        keyFile: /etc/ssl/traefik/localhost.key
EOF
fi

# Crear configuración de sesiones Redis para Redmine
echo "⚙️ Configurando almacenamiento de sesiones Redis..."
cat > redmine-config/session_store.rb << 'EOF'
require 'redis'

redis_config = {
  host: 'redis',
  port: 6379,
  db: 0,
  namespace: 'redmine_sessions'
}

Rails.application.config.session_store :redis_store,
  servers: ["redis://#{redis_config[:host]}:#{redis_config[:port]}/#{redis_config[:db]}"],
  expire_after: 120.minutes,
  key: '_redmine_session',
  threadsafe: true,
  secure: false,
  httponly: true
EOF

# Dar permisos apropiados
chmod 600 traefik/certs/*
chmod 755 setup.sh

echo "✅ Configuración completada!"
echo ""
echo "Para iniciar los servicios ejecuta:"
echo "  docker-compose up -d"
echo ""
echo "Los servicios estarán disponibles en:"
echo "  🌍 Redmine:     https://redmine.localhost"
echo "  📊 PgAdmin:     https://pgadmin.localhost"
echo "  📧 MailDev:     https://maildev.localhost"
echo "  🔧 Traefik:     https://traefik.localhost"
echo ""
echo "⚠️  Acepta los certificados autofirmados en tu navegador"