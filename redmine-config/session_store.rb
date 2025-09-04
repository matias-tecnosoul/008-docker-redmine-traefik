# Configuración básica de sesiones (cookie-based)
Rails.application.config.session_store :cookie_store,
  key: "_redmine_session",
  expire_after: 120.minutes,
  secure: false,
  httponly: true,
  same_site: :lax
