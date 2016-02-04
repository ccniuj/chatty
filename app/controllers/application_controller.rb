class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :configure_permitted_parameters, if: :devise_controller?
  layout :layout

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :name << :selfie_url
    p 'application controller'
  end

  private
  def layout
    false if devise_controller?
  end
end
