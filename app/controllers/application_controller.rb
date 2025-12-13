class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!

  def after_sign_in_path_for(_resource)
    closings_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
