module Middleware
  class StaticAssets
    def initialize(app)
      @app = app
    end

    def call(env)
      if env['PATH_INFO'].start_with?('/fonts/')
        env['PATH_INFO'] = "/assets" + env['PATH_INFO']
      elsif env['PATH_INFO'].start_with?('/assets/system/')
        env['PATH_INFO'] = "/assets" + env['PATH_INFO']
      end

      puts "Requesting: #{env['PATH_INFO']}"
      status, headers, response = @app.call(env)

      if status == 404
        puts "Asset not found: #{env['PATH_INFO']}"
      end

      [status, headers, response]
    end
  end
end