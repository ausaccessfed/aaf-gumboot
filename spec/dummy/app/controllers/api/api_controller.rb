module API
  class APIController < ApplicationController
    Forbidden = Class.new(StandardError)
    private_constant :Forbidden
    rescue_from Forbidden, with: :forbidden

    protect_from_forgery with: :null_session
    before_action :permitted?

    attr_reader :subject

    after_action do
      unless @access_checked
        method = "#{self.class.name}##{params[:action]}"
        fail("No access control performed by #{method}")
      end
    end

    protected

    def permitted?
      # Verified DN pushed by nginx following successful client SSL verification
      # Nginx is always going to do a better job of terminating SSL then we can
      @x509_dn = request.headers['HTTP_X509_DN']
                 .try(:force_encoding, 'UTF-8')

      head :unauthorized unless @x509_dn

      # Ensure API subject exists and is functioning
      @subject = APISubject.find_by x509_dn: @x509_dn
    end

    def check_access!(action)
      fail(Forbidden) unless @subject.permits?(action)
      @access_checked = true
    end

    def public_action
      @access_checked = true
    end

    def forbidden
      render nothing: true, status: 403
    end
  end
end
