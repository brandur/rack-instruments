require "uuidtools"

module Rack
  class Instruments
    def initialize(app)
      @app = app
    end

    def call(env)
      request_id = UUIDTools::UUID.timestamp_create.to_s
      request_start = Time.now
      Scrolls.log :instrumentation_start,
        id: request_id,
        method: env["REQUEST_METHOD"],
        route: env["REQUEST_PATH"],
        ip: env["REMOTE_ADDR"]

      env["REQUEST_ID"] = request_id
      status, headers, response = @app.call(env)

      Scrolls.log :instrumentation_end,
        id: request_id,
        method: env["REQUEST_METHOD"],
        route: env["REQUEST_PATH"],
        ip: env["REMOTE_ADDR"],
        elapsed: "#{Integer((Time.now - request_start) * 1000)}ms"

      [status, headers, response]
    end
  end
end
