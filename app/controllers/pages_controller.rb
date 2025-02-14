class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:unauthorized]
  def home
  end

  def unauthorized
  end
end
