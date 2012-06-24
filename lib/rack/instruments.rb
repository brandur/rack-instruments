module Rack
  class Instruments
    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) \
        if self.class.ignore_extensions.any? { |ext|
          env["REQUEST_PATH"] =~ /\.#{ext}$/
        }

      request_id = self.class.id_generator.call
      status, headers, response = nil, nil, nil

      # make ID of the request accessible to consumers down the stack
      env["REQUEST_ID"] = request_id

      Slides.log(:instrumentation,
        method: env["REQUEST_METHOD"],
        path:   env["REQUEST_PATH"],
        ip:     env["X-FORWARDED-FOR"] || env["HTTP_X_FORWARDED_FOR"] ||
          env["REMOTE_ADDR"],
        id:     request_id,
        status: -> { status }) do
          status, headers, response = @app.call(env)
      end

      [status, headers, response]
    end
  end

  module InstrumentsConfig
    def self.extended(base)
      base.id_generator = -> { rand(36**8).to_s(36) }
      base.ignore_extensions = %w{css gif ico jpg js jpeg pdf png}
    end

    attr_accessor :id_generator
    attr_accessor :ignore_extensions

    def configure
      yield self
    end

    def ignore_extensions
      @ignore_extensions || []
    end
  end
  Instruments.extend(InstrumentsConfig)
end
