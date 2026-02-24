module Users
  class RegistrationsController < Devise::RegistrationsController
    def create
      email = sign_up_params[:email].to_s.strip.downcase
      signup_code = params.dig(:user, :signup_code).to_s.strip

      if signup_code.blank?
        return handle_missing_email if email.blank?
        return handle_missing_owner_email if owner_email.blank?

        request = SignupRequest.issue_for!(email)
        unless send_signup_code_email(email, request.code)
          build_resource(sign_up_params)
          resource.errors.add(:base, "No se pudo enviar el código. Intenta de nuevo en unos minutos.")
          clean_up_passwords(resource)
          render :new, status: :unprocessable_entity
          return
        end

        build_resource(sign_up_params)
        resource.errors.add(:signup_code, "Necesitas el código del dueño para continuar.")
        flash.now[:notice] = "Se envió un código al dueño. Pídelo y vuelve a intentar."
        clean_up_passwords(resource)
        render :new, status: :unprocessable_entity
        return
      end

      signup_request = SignupRequest.valid_for(email, signup_code)
      unless signup_request
        build_resource(sign_up_params)
        resource.errors.add(:signup_code, "Código inválido o expirado.")
        clean_up_passwords(resource)
        render :new, status: :unprocessable_entity
        return
      end

      super do |resource|
        signup_request.mark_used! if resource.persisted?
      end
    end

    protected

    def sign_up_params
      params.require(:user).permit(:email, :password, :password_confirmation, :name, :code)
    end

    private

    def handle_missing_email
      build_resource(sign_up_params)
      resource.errors.add(:email, "es requerido para solicitar acceso.")
      clean_up_passwords(resource)
      render :new, status: :unprocessable_entity
    end

    def handle_missing_owner_email
      build_resource(sign_up_params)
      resource.errors.add(:base, "Falta configurar el correo del dueño (OWNER_EMAIL).")
      clean_up_passwords(resource)
      render :new, status: :unprocessable_entity
    end

    def owner_email
      ENV.fetch("OWNER_EMAIL", "juanjos.finance@gmail.com")
    end

    def send_signup_code_email(email, code)
      SignupRequestMailer.approval_code(email, code)&.deliver_now
      true
    rescue Net::SMTPError, IOError, SocketError, Timeout::Error => error
      Rails.logger.error("Signup code email delivery failed: #{error.class}: #{error.message}")
      false
    end
  end
end
