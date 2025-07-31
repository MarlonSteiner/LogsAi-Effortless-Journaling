# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    # Permit name and surname for sign up
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :surname])

    # Permit name and surname for account update
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :surname])
  end

  # Search function
  def set_search_data
    # Only set if user is signed in and you need it
    @recent_entries = current_user&.journal_entries&.recent&.limit(5)
  end
end
