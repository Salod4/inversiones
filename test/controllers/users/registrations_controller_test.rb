require "test_helper"
require "net/smtp"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "returns unprocessable entity when signup code email fails to send" do
    email = "salomon+smtp_failure@example.com"
    fake_mail = Object.new

    fake_mail.define_singleton_method(:deliver_now) do
      raise Net::SMTPAuthenticationError, "451 Authentication failed: Maximum credits exceeded"
    end

    assert_difference("SignupRequest.count", 1) do
      assert_no_difference("User.count") do
        SignupRequestMailer.stub(:approval_code, ->(_email, _code) { fake_mail }) do
          post user_registration_path, params: {
            user: {
              name: "Salomon",
              email: email,
              password: "password123",
              password_confirmation: "password123",
              signup_code: ""
            }
          }
        end
      end
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "No se pudo enviar el código"
  end
end
