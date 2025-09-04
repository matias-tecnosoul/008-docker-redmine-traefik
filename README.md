# 008-docker-redmine-traefik
# Redmine Escalado con Docker Compose y Traefik

Este proyecto implementa una solución completa para ejecutar Redmine escalado con múltiples instancias, utilizando Traefik como load balancer con manejo de sesiones sticky.

## Arquitectura

- **Traefik**: Load balancer con service discovery automático y terminación SSL
- **Redmine**: 3 instancias escaladas horizontalmente
- **PostgreSQL**: Base de datos principal
- **PgAdmin**: Administrador de base de datos PostgreSQL
- **MailDev**: Servidor de correo para desarrollo/testing

## Manejo de Sesiones

El problema principal al escalar Redmine es el manejo de sesiones. Por defecto, Rails almacena las sesiones en memoria, lo que causa problemas cuando las requests van a diferentes instancias.

### Solución implementada:

1. **Sticky sessions con Traefik**: Usa cookies para dirigir al usuario a la misma instancia
2. **Cookie name personalizado**: `redmine_session` para consistencia
3. **Health checks robustos**: Verificación en endpoint `/login`

## Configuración

### 1. Levantar los servicios

```bash
# Iniciar en background
docker compose up -d

# Ver logs
docker compose logs -f

# Verificar servicios
docker compose ps
```

### 2. Acceder a los servicios

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| Redmine | https://redmine.localhost | admin/admin (primer login) |
| PgAdmin | https://pgadmin.localhost | admin@example.com / admin123 |
| MailDev | https://maildev.localhost | - |
| Traefik Dashboard | http://traefik.localhost:8080 | - |

## Detalles técnicos

### Escalado de Redmine

- **redmine-1**: Instancia principal que ejecuta migraciones de BD
- **redmine-2/3**: Instancias secundarias que skipean migraciones
- **Dependencias controladas**: Las instancias esperan a que la principal esté healthy

### Load Balancing con Traefik

Traefik utiliza:
- **Service Discovery**: Detecta automáticamente los 3 contenedores de Redmine
- **Health Checks**: Verificación en `/login` cada 10 segundos
- **Sticky Sessions**: Cookie `redmine_session` mantiene al usuario en la misma instancia
- **SSL Termination**: HTTPS con certificados autofirmados

### Configuración crítica

```yaml
# Health checks optimizados
traefik.http.services.redmine.loadbalancer.healthcheck.path=/login
traefik.http.services.redmine.loadbalancer.healthcheck.interval=10s

# Sticky sessions
traefik.http.services.redmine.loadbalancer.sticky.cookie=true
traefik.http.services.redmine.loadbalancer.sticky.cookie.name=redmine_session

# Red correcta para conectividad
traefik.docker.network=traefik-net
```

### Redes

- **traefik-net**: Red pública para servicios expuestos (172.19.0.0/24)
- **backend**: Red privada para comunicación entre servicios (172.18.0.0/24)
- **Conectividad garantizada**: Todos los servicios conectados a las redes apropiadas

### Volúmenes persistentes

- `postgres_data`: Datos de PostgreSQL
- `redmine_files`: Archivos subidos a Redmine
- `redmine_plugins`: Plugins de Redmine
- `redmine_config`: Configuración compartida entre instancias
- `pgadmin_data`: Configuración de PgAdmin

## Verificación del escalado

```bash
# Ver las 3 instancias de Redmine
docker compose ps redmine

# Verificar balanceo en Traefik dashboard
curl -s http://traefik.localhost:8080/api/http/services | jq .

# Test de carga
for i in {1..10}; do
  curl -s -k https://redmine.localhost | grep "Redmine" | head -1
done
```

## Troubleshooting

### Problemas comunes resueltos

1. **Migraciones concurrentes**: Solo redmine-1 ejecuta migraciones, las demás skipean
2. **Configuración compartida**: Volumen `redmine_config` para database.yml
3. **Conectividad de red**: Traefik conectado a ambas redes (traefik-net y backend)
4. **Health checks**: Usando endpoint `/login` en lugar de `/`

### Certificados SSL

Los certificados son autofirmados. Para aceptarlos:
- Navegar a cada URL y aceptar la excepción de seguridad
- O importar certificados desde `./traefik/certs/`

### Verificar conectividad

```bash
# Test de resolución DNS local
ping redmine.localhost
ping pgadmin.localhost

# Verificar redes de contenedores
docker inspect <container_id> --format='{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}'
```

## Comandos útiles

```bash
# Reiniciar solo Redmine
docker compose restart redmine-1 redmine-2 redmine-3

# Ver logs específicos
docker compose logs redmine-1
docker compose logs redmine-2
docker compose logs redmine-3

# Limpiar todo
docker compose down -v
```

