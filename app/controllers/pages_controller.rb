class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:unauthorized]

  def home; end

  def search
    @search_params = params.permit(:q, :tranche_effectifs_unite_legale, :section_activite_principale, departments: [])
  end

  def unauthorized; end
end
