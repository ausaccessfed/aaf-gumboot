class ApplicationController < ActionController::Base
  Forbidden = Class.new(StandardError)
  private_constant :Forbidden
  rescue_from Forbidden, with: :forbidden

  Unauthorized = Class.new(StandardError)
  private_constant :Unauthorized
  rescue_from Unauthorized, with: :unauthorized

  protect_from_forgery with: :exception
  before_action :ensure_authenticated
  after_action :ensure_access_checked

  attr_reader :subject

  protected

  def ensure_authenticated
    return redirect_to('/auth/login') unless session[:subject_id]

    @subject = Subject.find(session[:subject_id])
    fail(Unauthorized, 'Subject not functional') unless @subject.functioning?
  rescue ActiveRecord::RecordNotFound
    raise(Unauthorized, 'Subject invalid')
  end

  def ensure_access_checked
    return if @access_checked

    method = "#{self.class.name}##{params[:action]}"
    fail("No access control performed by #{method}")
  end

  def check_access!(action)
    fail(Forbidden) unless subject.permits?(action)
    @access_checked = true
  end

  def public_action
    @access_checked = true
  end

  def unauthorized
    reset_session
    render 'errors/unauthorized', status: :unauthorized
  end

  def forbidden
    render 'errors/forbidden', status: :forbidden
  end
end
