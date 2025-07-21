class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # ↑ Security: Prevents hackers from submitting fake forms to your app

  before_action :authenticate_user!
  # ↑ Forces users to login before accessing ANY page in your app

  before_action :configure_permitted_parameters, if: :devise_controller?
  # ↑ Only runs the method below when user is on Devise pages (login/signup)

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :surname])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :surname])
  end
  # ↑ Allows name and surname fields in signup/profile forms
end
