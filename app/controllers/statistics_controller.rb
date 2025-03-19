class StatisticsController < ApplicationController
  def index
    payload = {
      resource: { dashboard: 2 },
      params: {},
      exp: Time.now.to_i + (60 * 10)
    }
    token = JWT.encode payload, ENV['METABASE_SECRET_KEY']

    @iframe_url = "#{ENV['METABASE_SITE_URL']}/embed/dashboard/#{token}#bordered=true&titled=true"
  end
end 