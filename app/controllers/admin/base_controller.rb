# app/controllers/admin/base_controller.rb
module Admin
  class BaseController < ApplicationController
    before_action :verify_admin

    private

    def verify_admin
      # TODO : Redirect to an error page unless the current_user is an admin
    end
  end
end