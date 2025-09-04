# 008-docker-redmine-traefik
# Redmine Escalado con Docker Compose y Traefik

Este proyecto implementa una solución completa para ejecutar Redmine escalado con múltiples instancias, utilizando Traefik como load balancer y Redis para el manejo de sesiones.

## Arquitectura

- **Traefik**: Load balancer con service discovery automático y terminación SSL
- **Redmine**: 3 instancias escaladas horizontalmente
- **PostgreSQL**: Base de datos principal
- **Redis**: Almacenamiento de sesiones compartidas
- **PgAdmin**: Administrador de base de datos PostgreSQL
- **MailDev**: Servidor de correo para desarrollo/testing

## Manejo de Sesiones

El problema principal al escalar Redmine es el manejo de sesiones. Por defecto, Rails almacena las sesiones en cookies o en archivos locales, lo que causa problemas cuando las requests van a diferentes instancias.

### Solución implementada:

1. **Redis como session store**: Configurado en `redmine-config/session_store.rb`
2. **Sesiones compartidas**: Todas las instancias de Redmine comparten el mismo Redis
3. **Sticky sessions**: Traefik usa cookies para dirigir al usuario a la misma instancia (backup)

## Configuración

### 1. Preparar el entorno

```bash
# Hacer ejecutable y correr el script de setup
chmod +x setup.sh
./setup.sh
```

### 2. Levantar los servicios

```bash
# Iniciar en background
docker compose up -d

# Ver logs
docker compose logs -f

# Verificar servicios
docker compose ps
```

### 3. Acceder a los servicios

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| Redmine | https://redmine.localhost | admin/admin (por defecto) |
| PgAdmin | https://pgadmin.localhost | admin@example.com / admin123 |
| MailDev | https://maildev.localhost | - |
| Traefik Dashboard | https://traefik.localhost | - |

## Detalles técnicos

### Escalado de Redmine

```yaml
deploy:
  replicas: 3
```

Traefik automáticamente detecta las 3 instancias y distribuye la carga entre ellas.

### Load Balancing

Traefik utiliza:
- **Service Discovery**: Detecta automáticamente los contenedores
- **Health Checks**: Verifica que los servicios estén saludables
- **Sticky Sessions**: Mantiene al usuario en la misma instancia usando cookies
- **SSL Termination**: Maneja certificados HTTPS

### Redes

- **traefik-net**: Red pública para servicios expuestos
- **backend**: Red privada para comunicación entre servicios

### Volúmenes persistentes

- `postgres_data`: Datos de PostgreSQL
- `redmine_files`: Archivos subidos a Redmine
- `redmine_plugins`: Plugins de Redmine
- `pgadmin_data`: Configuración de PgAdmin

## Verificación del escalado

```bash
# Ver las instancias de Redmine
docker compose ps redmine

# Logs de todas las instancias
docker compose logs redmine

# Verificar balanceador
curl -k https://redmine.localhost
```

## Troubleshooting

### Certificados SSL

Los certificados son autofirmados, por lo que el navegador mostrará una advertencia. Para aceptarlos:

1. Ve a cada URL
2. Acepta el certificado autofirmado
3. O agrega los certificados a tu trust store del sistema

### Problemas de sesiones

Si hay problemas con sesiones:

```bash
# Verificar Redis
docker compose exec redis redis-cli ping

# Ver logs de Redmine
docker compose logs redmine

# Restart específico de Redmine
docker compose restart redmine
```

### Verificar conectividad

```bash
# Test de resolución DNS local
ping redmine.localhost
ping pgadmin.localhost

# En Arch/Manjaro, verificar systemd-resolved
systemd-resolve --status
```

## Comandos útiles

```bash
# Escalar Redmine manualmente
docker compose up -d --scale redmine=5

# Rebuild y restart
docker compose down
docker compose up -d --build

# Limpiar todo
docker compose down -v
docker system prune -f
```

## Notas para producción

Para un entorno de producción considera:

1. **Certificados reales**: Usar Let's Encrypt o certificados comerciales
2. **Secrets management**: No hardcodear passwords
3. **Backup strategy**: Para bases de datos y archivos
4. **Monitoring**: Añadir Prometheus/Grafana
5. **Security**: Configurar firewalls y accesos más restrictivos