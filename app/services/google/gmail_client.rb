require "google/apis/gmail_v1"
require "googleauth"
require "mail"
require "base64"

module Google
  class GmailClient
    class MissingCredentialsError < StandardError; end

    SCOPE = "https://www.googleapis.com/auth/gmail.compose"

    FakeDraft = Struct.new(:id, :message)

    def initialize(config = Google::GmailConfig.new)
      @config = config
      @client_id     = config.client_id
      @client_secret = config.client_secret
      @refresh_token = config.refresh_token
      @user_id       = config.from_email || "me"
    end

    def create_draft(to:, subject:, body:, attachments: [])
      return fake_draft if mock_mode?

      ensure_credentials_present!

      mime_message = build_mime(to: to, subject: subject, body: body, attachments: attachments)
      encoded = encode_message(mime_message)

      draft = ::Google::Apis::GmailV1::Draft.new(
        message: ::Google::Apis::GmailV1::Message.new(raw: encoded)
      )
      service.create_user_draft(@user_id, draft)
    rescue ::Google::Apis::ClientError => e
      Rails.logger.error("[gmail] ClientError #{e.status_code}: #{e.message} #{e.body}")
      raise
    end

    private

    def mock_mode?
      Rails.env.test? || ENV["GMAIL_DRAFTS_DISABLED"] == "1"
    end

    def fake_draft
      FakeDraft.new("mock-draft-id", "gmail draft skipped (mock mode)")
    end

    def ensure_credentials_present!
      missing = @config.missing_keys

      return if missing.empty?

      msg = "Missing Google OAuth credentials: #{missing.join(', ')}"
      if Rails.env.test?
        return
      elsif Rails.env.development?
        raise MissingCredentialsError, msg
      else
        raise ArgumentError, msg
      end
    end

    def service
      @service ||= begin
        svc = ::Google::Apis::GmailV1::GmailService.new
        svc.authorization = authorization
        svc
      end
    end

    def authorization
      @authorization ||= begin
        client = Signet::OAuth2::Client.new(
          token_credential_uri: "https://oauth2.googleapis.com/token",
          client_id: @client_id,
          client_secret: @client_secret,
          refresh_token: @refresh_token,
          scope: SCOPE
        )
        client.fetch_access_token!
        client
      end
    end

    def build_mime(to:, subject:, body:, attachments:)
      mail = Mail.new
      mail.date = Time.zone.now
      mail.to = to
      mail.subject = subject
      mail.content_type = "multipart/mixed"
      mail.charset = "UTF-8"

      mail.text_part = Mail::Part.new do
        content_type "text/plain; charset=UTF-8"
        body body
      end

      attachments.each do |att|
        mail.attachments[att[:filename]] = {
          mime_type: att[:mime_type] || "application/octet-stream",
          content: att[:data]
        }
      end

      mail
    end

    def encode_message(mail)
      Base64.urlsafe_encode64(mail.to_s).delete("=")
    end
  end
end
