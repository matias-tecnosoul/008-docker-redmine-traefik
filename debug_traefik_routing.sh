#!/bin/bash

echo "🔍 Diagnóstico completo del sistema..."

echo "1️⃣ Estado de contenedores:"
docker compose ps

echo ""
echo "2️⃣ Verificando logs de Redmine (últimas 10 líneas):"
echo "--- redmine-1 ---"
docker compose logs --tail=10 redmine-1

echo ""
echo "--- redmine-2 ---" 
docker compose logs --tail=10 redmine-2

echo ""
echo "--- redmine-3 ---"
docker compose logs --tail=10 redmine-3

echo ""
echo "3️⃣ Verificando conectividad directa a contenedores:"
echo "Probando acceso directo a redmine-1 puerto 3000..."
docker compose exec redmine-1 curl -s localhost:3000 | head -5 || echo "❌ Redmine-1 no responde localmente"

echo ""
echo "4️⃣ Verificando servicios de Traefik:"
curl -s http://localhost:8080/api/http/services | jq -r '.[] | select(.name | contains("redmine")) | "Service: " + .name + " | Status: " + .status'

echo ""
echo "5️⃣ Verificando routers de Traefik:"
curl -s http://localhost:8080/api/http/routers | jq -r '.[] | select(.rule | contains("redmine")) | "Router: " + .name + " | Rule: " + .rule + " | Status: " + .status'

echo ""
echo "6️⃣ Verificando redes Docker:"
echo "Red traefik-net:"
docker network inspect 008-docker-redmine-traefik_traefik-net | jq -r '.[] | .Containers | keys[]' 2>/dev/null || echo "Error inspeccionando red"

echo ""
echo "7️⃣ Test de conectividad interna:"
echo "Desde Traefik hacia redmine-1:"
docker compose exec traefik wget -qO- --timeout=5 http://redmine-1:3000 2>/dev/null | head -5 || echo "❌ Traefik no puede conectar a redmine-1"

echo ""
echo "8️⃣ Verificando certificados SSL:"
ls -la traefik/certs/ 2>/dev/null || echo "❌ Directorio de certificados no encontrado"

echo ""
echo "9️⃣ Verificar variables de entorno problemáticas:"
docker compose exec redmine-1 printenv | grep -E "(REDMINE_|RAILS_)" || echo "❌ No se pueden ver variables de entorno"