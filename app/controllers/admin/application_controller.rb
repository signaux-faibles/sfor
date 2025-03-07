# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    impersonates :user
    before_action :authenticate_admin

    def authenticate_admin
      unless current_user && current_user.segment.name == "sf"
        flash.now[:alert] = "Vous n'avez pas l'authorisation d'accéder à cette section"
        redirect_to root_url
      end
    end

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end
  end
end
