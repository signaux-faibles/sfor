module Admin
  class UsersController < Admin::ApplicationController
    def impersonate
      user = User.find(params[:user_id])

      impersonate_user(user)
      redirect_to root_path
    end

    def discard
      user = User.find(params[:user_id])

      if user.discard
        flash[:notice] = t(".success")
      else
        flash[:alert] = t(".error")
      end

      redirect_to admin_users_path
    end

    def undiscard
      user = User.find(params[:user_id])

      if user.undiscard
        flash[:notice] = t(".success")
      else
        flash[:alert] = t(".error")
      end

      redirect_to admin_users_path
    end

    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   super
    #   send_foo_updated_email(requested_resource)
    # end
    def destroy
      user = User.find(params[:id])

      if user.discard
        flash[:notice] = t("admin.users.discard.success")
      else
        flash[:alert] = t("admin.users.discard.error")
      end

      redirect_to admin_users_path
    end

    # Override this method to specify custom lookup behavior.
    # This will be used to set the resource for the `show`, `edit`, and `update`
    # actions.
    #
    # def find_resource(param)
    #   Foo.find_by!(slug: param)
    # end

    # The result of this lookup will be available as `requested_resource`

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    #
    # def scoped_resource
    #   if current_user.super_admin?
    #     resource_class
    #   else
    #     resource_class.with_less_stuff
    #   end
    # end

    # Override `resource_params` if you want to transform the submitted
    # data before it's persisted. For example, the following would turn all
    # empty values into nil values. It uses other APIs such as `resource_class`
    # and `dashboard`:
    #
    # def resource_params
    #   params.require(resource_class.model_name.param_key).
    #     permit(dashboard.permitted_attributes(action_name)).
    #     transform_values { |value| value == "" ? nil : value }
    # end

    # See https://administrate-demo.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
