require "stringio"

require_relative "test_helper"

module Slides
  def self.log(event, data)
    $data = data
    yield if block_given?
  end
end

describe Rack::Instruments do
  before do
    $data, $env = nil, nil
  end

  def app
    ->(env) { $env = env ; [200, {}, ""] }
  end

  def call(env={}, options={})
    Rack::Instruments.new(app, options).call(env)
  end

  it "reads request method" do
    call("REQUEST_METHOD" => "GET")
    assert_equal "GET", $data[:method]
  end

  it "reads request path" do
    call("REQUEST_PATH" => "/index")
    assert_equal "/index", $data[:path]
  end

  it "prefers to read IP from X-FORWARDED-FOR" do
    call("HTTP_X_FORWARDED_FOR" => "1.2.3.4", "REMOTE_ADDR" => "2.3.4.5")
    assert_equal "1.2.3.4", $data[:ip]
  end

  it "prefers to read IP from HTTP_X_FORWARDED_FOR" do
    call("HTTP_X_FORWARDED_FOR" => "1.2.3.4", "REMOTE_ADDR" => "2.3.4.5")
    assert_equal "1.2.3.4", $data[:ip]
  end

  it "will read IP from REMOTE_ADDR without a proxy" do
    call("REMOTE_ADDR" => "2.3.4.5")
    assert_equal "2.3.4.5", $data[:ip]
  end

  it "includes a request ID" do
    call()
    assert_match Rack::Instruments::UUID_PATTERN, $data[:request_id]
  end

  it "includes a set of request IDs from headers" do
    request_ids = [SecureRandom.uuid, SecureRandom.uuid]
    call("HTTP_REQUEST_ID" => request_ids.join(", "))
    request_ids = $data[:request_id].split(",")
    assert_equal 3, request_ids.count
    request_ids.each do |id|
      assert_match Rack::Instruments::UUID_PATTERN, id
    end
  end

  it "ignores invalid request IDs coming from headers" do
    call("HTTP_REQUEST_ID" => "invalid-request-id")
    assert_equal 1, $data.select { |k, v| k == :request_id }.count
  end

  it "injects a request ID into the environment" do
    call()
    assert_equal $data[:request_id], $env["REQUEST_ID"]
  end

  it "injects a set of request IDs into the environment" do
    request_ids = [SecureRandom.uuid, SecureRandom.uuid]
    call("HTTP_REQUEST_ID" => request_ids.join(", "))
    assert_equal $data[:request_id], $env["REQUEST_IDS"]
  end

  it "includes the status that bubbled up" do
    call()
    # normally, the logger will call this lambda
    assert_equal 200, $data[:status].call
  end

  it "ignores static extensions" do
    call("REQUEST_PATH" => "/logo.png")
    assert_equal nil, $attrs
  end

  it "takes a context option" do
    call({}, { context: { app: "my-app" } })
    assert_equal "my-app", $data[:app]
  end

  it "allows header-injected request IDs to be disabled" do
    request_ids = [SecureRandom.uuid, SecureRandom.uuid]
    call({ "HTTP_REQUEST_ID" => request_ids.join(", ") },
      { header_request_ids: false })
    assert_equal 1, $data.select { |k, v| k == :request_id }.count
  end

  it "takes ignored extensions" do
    call({ "REQUEST_PATH" => "/logo.png" }, { ignore_extensions: nil })
    assert_equal "/logo.png", $data[:path]
  end

  it "takes a request ID generator" do
    call({}, { request_id_generator: -> { "my-id" } })
    assert_equal "my-id", $data[:request_id]
  end

  it "takes a request ID pattern" do
    call({ "HTTP_REQUEST_ID" => "my-id" },
      { request_id_pattern: /my-id/ })
    assert_match /,my-id/, $data[:request_id]
  end
end
