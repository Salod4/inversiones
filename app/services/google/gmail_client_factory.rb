# frozen_string_literal: true

module Google
  class GmailClientFactory
    def self.build
      config = Google::GmailConfig.new

      return Google::NullGmailClient.new unless config.present?

      Google::GmailClient.new(config)
    rescue Google::GmailClient::MissingCredentialsError
      Google::NullGmailClient.new
    end
  end
end
