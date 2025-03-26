class StatisticsController < ApplicationController
  def index
    payload = {
      resource: { dashboard: 2 },
      params: {},
      exp: Time.now.to_i + (60 * 10)
    }
    token = JWT.encode payload, ENV.fetch("METABASE_SECRET_KEY", nil)

    @iframe_url = "#{ENV.fetch('METABASE_SITE_URL', nil)}/embed/dashboard/#{token}#bordered=true&titled=true"
  end
end
