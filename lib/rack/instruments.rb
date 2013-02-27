require "securerandom"
require "slides"

module Rack
  class Instruments
    def initialize(app, options={})
      @app = app

      @context           = options[:context]
      @id_generator      = options.fetch(:id_generator,
        lambda { SecureRandom.uuid })
      @ignore_extensions = options.fetch(:ignore_extensions,
        %w{css gif ico jpg js jpeg pdf png})
    end

    def call(env)
      return @app.call(env) \
        if @ignore_extensions && @ignore_extensions.any? { |ext|
          env["REQUEST_PATH"] =~ /\.#{ext}$/
        }

      request_id = @id_generator.call
      status, headers, response = nil, nil, nil

      # make ID of the request accessible to consumers down the stack
      env["REQUEST_ID"] = request_id

      data = {
        :method => env["REQUEST_METHOD"],
        :path   => env["REQUEST_PATH"],
        :ip     => env["X-FORWARDED-FOR"] || env["HTTP_X_FORWARDED_FOR"] ||
          env["REMOTE_ADDR"],
        :id     => request_id,
        :status => lambda { status }
      }
      data.merge!(@context) if @context

      Slides.log(:instrumentation, data) do
        status, headers, response = @app.call(env)
      end

      [status, headers, response]
    end
  end
end
