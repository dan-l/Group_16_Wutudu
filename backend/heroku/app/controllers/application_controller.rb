class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # TODO: WE WANT TO TURN THIS BACK ON
  protect_from_forgery with: :null_session
end
