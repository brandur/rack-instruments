rack-instruments
================

Rack middleware providing extremely basic instrumentation. Idea based on [ryandotsmith/instruments](https://github.com/ryandotsmith/instruments).

After installation and configuration, two additional logging lines (sent to `$stdout`) will accompany any requests to your applications:

    instrumentation method=GET path=/ ip=74.207.253.12 id=pcl9yyje at=start
    instrumentation method=GET path=/ ip=74.207.253.12 id=pcl9yyje status=200 at=finish elapsed=1ms

The instrumentation middleware also injects a request ID into your request's environment to help log all events associated with a particular request. This can be abstracted with a logging helper:

``` ruby
helpers do
  def log(attrs = {}, &blk)
    Scrolls.log(attrs.merge!(id: request.env["REQUEST_ID"]), &blk)
  end
end

get "/" do
  log :get_index
end
```

A request to / will then appear on your `$stdout` with the instrumentation lines along with:

    get_index id=pcl9yyje

Installation
------------

In your `Gemfile`:

``` ruby
gem "rack-instruments"
```

In your `config.ru`:

``` ruby
use Rack::Instruments
```

Configuration
-------------

Use `configure` with a block to change one of these settings:

* **context:** A hash of extra data context to include in the instrumentation.
* **id_generator:** Subroutine used to generate identifiers for the request.
* **ignore_extensions:** Array of extensions that shouldn't be instrumented. Defaults to well-known static files.

For example, to use UUIDs for ID generation:

``` ruby
Rack::Instruments.configure do |config|
  config.id_generator = -> { SecureRandom.uuid }
end
```

To disable ID generation:

``` ruby
Rack::Instruments.configure do |config|
  config.id_generator = -> { nil }
end
```

Testing
-------

    rake test
