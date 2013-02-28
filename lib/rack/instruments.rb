require "securerandom"
require "slides"

module Rack
  class Instruments
    UUID_PATTERN =
      /\A[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}\Z/

    def initialize(app, options={})
      @app = app

      @context                = (options[:context] || {}).
        map { |k, v| [k, v] }
      @id_generator           = options.fetch(:id_generator,
        lambda { SecureRandom.uuid })
      @ignore_extensions      = options.fetch(:ignore_extensions,
        %w{css gif ico jpg js jpeg pdf png})
      @use_header_request_ids = options.fetch(:use_header_request_ids, true)
    end

    def call(env)
      return @app.call(env) \
        if @ignore_extensions && @ignore_extensions.any? { |ext|
          env["REQUEST_PATH"] =~ /\.#{ext}$/
        }

      request_ids = [@id_generator.call] + extract_request_ids(env)
      status, headers, response = nil, nil, nil

      # make ID of the request accessible to consumers down the stack
      env["REQUEST_ID"] = request_ids

      data = [
        [:method, env["REQUEST_METHOD"]],
        [:path, env["REQUEST_PATH"]],
        [:ip, env["X-FORWARDED-FOR"] || env["HTTP_X_FORWARDED_FOR"] ||
          env["REMOTE_ADDR"]],
        [:status, lambda { status }],
      ]
      data += request_ids.map { |id| [:id, id] }
      data += @context if @context

      Slides.log_array(:instrumentation, data) do
        status, headers, response = @app.call(env)
      end

      [status, headers, response]
    end

    private

    def extract_request_ids(env)
      return [] unless @use_header_request_ids
      request_ids = []
      if env["HTTP_REQUEST_ID"]
        request_ids = env["HTTP_REQUEST_ID"].split(",")
        request_ids.map! { |id| id.strip }
        request_ids.select! { |id| id =~ UUID_PATTERN }
      end
      request_ids
    end
  end
end
