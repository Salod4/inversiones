# Configurar Gmail API para borradores en Inversiones

## Credenciales requeridas (variables de entorno)

- `GMAIL_CLIENT_ID`
- `GMAIL_CLIENT_SECRET`
- `GMAIL_REFRESH_TOKEN`
- `GMAIL_USER_EMAIL` (o usa `"me"` si aplica)

En producción son obligatorias. En desarrollo/test, si faltan, la app no llamará a la API y mostrará un mensaje claro.

## Pasos para obtener el refresh token

1. Crea un proyecto en Google Cloud Console.
2. Habilita la **Gmail API**.
3. Crea credenciales **OAuth Client** (tipo Desktop o Web).
4. Scope necesario: `https://www.googleapis.com/auth/gmail.compose`.
5. Obtén un authorization code y canjéalo por refresh_token. Ejemplo con Ruby:

```ruby
require "signet/oauth_2/client"
client = Signet::OAuth2::Client.new(
  client_id: ENV["GMAIL_CLIENT_ID"],
  client_secret: ENV["GMAIL_CLIENT_SECRET"],
  token_credential_uri: "https://oauth2.googleapis.com/token",
  redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
  scope: "https://www.googleapis.com/auth/gmail.compose"
)
puts "Visit:\n#{client.authorization_uri}"
print "Code: "
code = STDIN.gets.strip
client.code = code
token = client.fetch_access_token!
puts "refresh_token: #{token['refresh_token']}"
```

6. Exporta las variables de entorno en tu entorno (dotenv, credentials, etc.).

## Notas
- Si las credenciales faltan en producción, fallará con error explícito.
- En test o con `GMAIL_DRAFTS_DISABLED=1`, la creación de borradores se omite.
