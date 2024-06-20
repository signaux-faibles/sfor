OmniAuth.config.logger = Rails.logger
OmniAuth.config.on_failure = Proc.new { |env|
  message = env['omniauth.error.type']
  strategy = env['omniauth.error.strategy']
  Rails.logger.error("OmniAuth Error: #{message.inspect}")
  Rails.logger.error("OmniAuth Strategy: #{strategy.inspect}")
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
