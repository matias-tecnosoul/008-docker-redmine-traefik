# 1. Detener Apache local
sudo systemctl stop apache2 2>/dev/null || sudo systemctl stop httpd 2>/dev/null
echo "✅ Apache detenido temporalmente"

# 2. Detener servicios Docker actuales
docker-compose down
echo "✅ Servicios Docker detenidos"

# 3. Verificar que el puerto 80 esté libre
sudo netstat -tlnp | grep :80 || echo "✅ Puerto 80 libre"

# 4. Crear los directorios y archivos necesarios si no existen
mkdir -p traefik/certs
mkdir -p redmine-config

# 5. Generar certificado SSL si no existe
if [ ! -f "traefik/certs/localhost.crt" ]; then
    openssl req -x509 -newkey rsa:4096 \
        -keyout traefik/certs/localhost.key \
        -out traefik/certs/localhost.crt \
        -days 365 -nodes \
        -subj '/CN=localhost/subjectAltName=DNS:localhost,DNS:*.localhost'
    echo "✅ Certificado SSL generado"
fi

# 6. Crear configuración dinámica de Traefik
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
echo "✅ Configuración dinámica de Traefik creada"

# 7. Crear configuración de sesiones Redis para Redmine
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
echo "✅ Configuración de sesiones Redis creada"

echo ""
echo "🚀 Ahora actualiza tu docker-compose.yml y ejecuta:"
echo "   docker compose up -d"