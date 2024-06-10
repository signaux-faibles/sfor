# app/controllers/admin/establishments_controller.rb

module Admin
  class CampaignsController < BaseController
    def index
      @campaigns = Campaign.all
      @campaigns.each do |campaign|
        campaign.instance_variable_set(:@establishment_count, campaign.establishments.count)
      end
    end
  end
end