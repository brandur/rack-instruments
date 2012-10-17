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
    $attrs[:id].must_match /^[a-z0-9]{1,8}$/
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

  it "ignores static extensions" do
    call("REQUEST_PATH" => "/logo.png")
    $attrs.must_equal nil
  end
end

describe Rack::InstrumentsConfig do
  it "configures extra context" do
    Rack::Instruments.configure do |c|
      c.context = { app: "my-app" }
    end
    Rack::Instruments.context.must_equal({ app: "my-app" })
  end

  it "configures ID generation" do
    Rack::Instruments.configure do |c|
      c.id_generator = -> { "id" }
    end
    Rack::Instruments.id_generator.call.must_equal "id"
  end

  it "configures ignored extensions" do
    Rack::Instruments.configure do |c|
      c.ignore_extensions = nil
    end
    Rack::Instruments.ignore_extensions.must_equal []
  end
end
