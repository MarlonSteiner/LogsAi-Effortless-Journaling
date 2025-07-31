class ErrorsController < ApplicationController
  layout false

  def internal_server_error
    render status: :internal_server_error
  end
end
