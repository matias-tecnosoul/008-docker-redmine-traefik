# Configuración para almacenar sesiones en Redis
# Este archivo debe ir en redmine-config/session_store.rb

require 'redis'

# Configuración de Redis para sesiones
redis_config = {
  host: 'redis',
  port: 6379,
  db: 0,
  namespace: 'redmine_sessions'
}

# Configurar el store de sesiones de Rails para usar Redis
Rails.application.config.session_store :redis_store,
  servers: ["redis://#{redis_config[:host]}:#{redis_config[:port]}/#{redis_config[:db]}"],
  expire_after: 120.minutes,
  key: '_redmine_session',
  threadsafe: true,
  secure: false,
  httponly: true