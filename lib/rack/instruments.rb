require "securerandom"
require "slides"

module Rack
  class Instruments
    UUID_PATTERN =
      /\A[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}\Z/

    def initialize(app, options={})
      @app = app

      @context              = options[:context]
      @header_request_ids   = options.fetch(:header_request_ids, true)
      @ignore_extensions    = options.fetch(:ignore_extensions,
        %w{css gif ico jpg js jpeg pdf png})
      @request_id_generator = options.fetch(:request_id_generator,
        lambda { SecureRandom.uuid })
      @request_id_pattern   = options.fetch(:request_id_pattern, UUID_PATTERN)
    end

    def call(env)
      return @app.call(env) \
        if @ignore_extensions && @ignore_extensions.any? { |ext|
          env["REQUEST_PATH"] =~ /\.#{ext}$/
        }

      request_ids = [@request_id_generator.call]
      status, headers, response = nil, nil, nil

      # make ID of the request accessible to consumers down the stack
      env["REQUEST_ID"] = request_ids[0]

      # Extract request IDs from incoming headers as well. Can be used for
      # identifying a request across a number of components in SOA.
      if @header_request_ids
        request_ids += extract_request_ids(env)
        env["REQUEST_IDS"] = request_ids.join(",")
      end

      data = {
        method:     env["REQUEST_METHOD"],
        path:       env["REQUEST_PATH"],
        ip:         env["HTTP_X_FORWARDED_FOR"] || env["REMOTE_ADDR"],
        request_id: request_ids.join(","),
        status:     lambda { status },
      }
      data.merge!(@context) if @context

      Slides.log(:instrumentation, data) do
        status, headers, response = @app.call(env)
      end

      [status, headers, response]
    end

    private

    def extract_request_ids(env)
      request_ids = []
      if env["HTTP_REQUEST_ID"]
        request_ids = env["HTTP_REQUEST_ID"].split(",")
        request_ids.map! { |id| id.strip }
        request_ids.select! { |id| id =~ @request_id_pattern }
      end
      request_ids
    end
  end
end
