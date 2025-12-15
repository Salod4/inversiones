# frozen_string_literal: true

module Google
  class NullGmailClient
    Draft = Struct.new(:id, :message_id, :skipped, keyword_init: true)

    def create_draft(to:, subject:, body:, attachments: [])
      Rails.logger.info("[gmail] Using NullGmailClient: draft skipped (env lacks credentials or mock mode)")
      Draft.new(id: "dummy-draft", message_id: "dummy-msg", skipped: true)
    end
  end
end
