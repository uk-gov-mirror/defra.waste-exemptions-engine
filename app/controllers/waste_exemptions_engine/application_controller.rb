# frozen_string_literal: true

module WasteExemptionsEngine
  class ApplicationController < ::ApplicationController
    # A successful POST request redirects to the next form in the work flow. We have chosen to
    # differentiate 'good' rediection as 303 and 'bad' redirection as 302.
    UNSUCCESSFUL_REDIRECTION_CODE = 302
    SUCCESSFUL_REDIRECTION_CODE = 303

    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :exception

    # Use the host application's default layout
    layout "application"
  end
end
