class SignupRequestMailer < ApplicationMailer
  def approval_code(email, code)
    @email = email
    @code = code
    @requested_at = Time.zone.now

    owner_email = ENV.fetch("OWNER_EMAIL", "juanjos.finance@gmail.com")
    return if owner_email.blank?

    mail(
      to: owner_email,
      subject: "Código de registro para #{email}"
    )
  end
end
