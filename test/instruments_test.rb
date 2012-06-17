require "stringio"
require "test_helper"

module Slides
  def self.log(event, attrs)
    $attrs = attrs
    yield if block_given?
  end
end

describe Rack::Instruments do
  before do
    $attrs, $env = nil, nil
  end

  def app
    ->(env) { $env = env ; [200, {}, ""] }
  end

  def call(env = {})
    Rack::Instruments.new(app).call(env)
  end

  it "reads request method" do
    call("REQUEST_METHOD" => "GET")
    $attrs[:method].must_equal "GET"
  end

  it "reads request path" do
    call("REQUEST_PATH" => "/index")
    $attrs[:path].must_equal "/index"
  end

  it "prefers to read IP from X-FORWARDED-FOR" do
    call("X-FORWARDED-FOR" => "1.2.3.4", "REMOTE_ADDR" => "2.3.4.5")
    $attrs[:ip].must_equal "1.2.3.4"
  end

  it "prefers to read IP from HTTP_X_FORWARDED_FOR" do
    call("HTTP_X_FORWARDED_FOR" => "1.2.3.4", "REMOTE_ADDR" => "2.3.4.5")
    $attrs[:ip].must_equal "1.2.3.4"
  end

  it "will read IP from REMOTE_ADDR without a proxy" do
    call("REMOTE_ADDR" => "2.3.4.5")
    $attrs[:ip].must_equal "2.3.4.5"
  end

  it "includes a request ID" do
    call()
    $attrs[:id].must_match /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/
  end

  it "injects a request ID into the environment" do
    call()
    $env["REQUEST_ID"].must_equal $attrs[:id]
  end

  it "includes the status that bubbled up" do
    call()
    # normally, the logger will call this lambda
    $attrs[:status].call.must_equal 200
  end
end
