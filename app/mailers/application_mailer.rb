class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "juanjos.finance@gmail.com")
  layout "mailer"
end
