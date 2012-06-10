module Rack
  class Instruments
    def initialize(app)
      @app = app
    end

    def call(env)
      @start_request = Time.now
      status, headers, response = @app.call(env)
      Scrolls.log :instrumentation,
        method: env["REQUEST_METHOD"],
        route: env["REQUEST_PATH"],
        elapsed: "#{Integer((Time.now - @start_request) * 1000)}ms",
        ip: env["REMOTE_ADDR"]
      [status, headers, response]
    end
  end
end
