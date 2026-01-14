class SignupRequest < ApplicationRecord
  CODE_TTL = 1.day

  validates :email, presence: true
  validates :code, presence: true

  def self.issue_for!(email)
    normalized = email.to_s.strip.downcase
    raise ArgumentError, "Email requerido" if normalized.blank?

    transaction do
      where(email: normalized, used_at: nil).update_all(used_at: Time.current)
      create!(
        email: normalized,
        code: generate_code,
        expires_at: CODE_TTL.from_now
      )
    end
  end

  def self.valid_for(email, code)
    normalized = email.to_s.strip.downcase
    clean_code = code.to_s.strip
    return nil if normalized.blank? || clean_code.blank?

    where(email: normalized, code: clean_code, used_at: nil)
      .where("expires_at IS NULL OR expires_at >= ?", Time.current)
      .order(created_at: :desc)
      .first
  end

  def mark_used!
    update!(used_at: Time.current)
  end

  def expired?
    expires_at.present? && Time.current > expires_at
  end

  def self.generate_code
    format("%06d", SecureRandom.random_number(1_000_000))
  end
end
