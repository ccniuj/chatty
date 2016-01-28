class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  layout :layout

  private
  def layout
    # only turn it off for login pages:
    # is_a?(Devise::SessionsController) ? false : "application"
    # or turn layout off for every devise controller:
    false if devise_controller?
  end
end
