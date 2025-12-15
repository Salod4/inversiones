# frozen_string_literal: true

module Google
  class GmailConfig
    attr_reader :client_id, :client_secret, :refresh_token, :from_email

    def initialize
      credentials = Rails.application.credentials.dig(:gmail) || {}
      env = {
        client_id: ENV["GMAIL_CLIENT_ID"],
        client_secret: ENV["GMAIL_CLIENT_SECRET"],
        refresh_token: ENV["GMAIL_REFRESH_TOKEN"],
        from_email: ENV["GMAIL_USER_EMAIL"]
      }

      @client_id     = credentials[:client_id].presence     || env[:client_id]
      @client_secret = credentials[:client_secret].presence || env[:client_secret]
      @refresh_token = credentials[:refresh_token].presence || env[:refresh_token]
      @from_email    = credentials[:from_email].presence    || env[:from_email] || "me"
    end

    def present?
      client_id.present? && client_secret.present? && refresh_token.present?
    end

    def missing_keys
      [].tap do |keys|
        keys << "GMAIL_CLIENT_ID" if client_id.blank?
        keys << "GMAIL_CLIENT_SECRET" if client_secret.blank?
        keys << "GMAIL_REFRESH_TOKEN" if refresh_token.blank?
      end
    end
  end
end
