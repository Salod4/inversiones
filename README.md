# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
- Configurar credenciales de Gmail en `bin/rails credentials:edit`:

```
gmail:
  client_id: "..."
  client_secret: "..."
  refresh_token: "..."
  from_email: "tu_correo@gmail.com"
```

- Scope requerido: https://www.googleapis.com/auth/gmail.compose
- Para obtener `refresh_token`:
  1. Crea proyecto en Google Cloud, habilita Gmail API y un OAuth client (Desktop/Web).
  2. Usa un script con `Signet::OAuth2::Client` o `curl` para intercambiar el authorization code por el refresh token.
  3. Guarda las variables anteriores.
