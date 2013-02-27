rack-instruments
================

Rack middleware providing extremely basic instrumentation.

After installation and configuration, two additional logging lines (sent to `$stdout`) will accompany any requests to your applications:

    instrumentation method=GET path=/ ip=74.207.253.12 id=f9daa07c-fb93-489a-b9f4-436f71bf85c8 at=start
    instrumentation method=GET path=/ ip=74.207.253.12 id=f9daa07c-fb93-489a-b9f4-436f71bf85c8 status=200 at=finish elapsed=1ms

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

    get_index id=f9daa07c-fb93-489a-b9f4-436f71bf85c8

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

Configure the module right in your middleware stack with any of the following options:

* **context:** A hash of extra data context to include in the instrumentation.
* **id_generator:** Subroutine used to generate identifiers for the request.
* **ignore_extensions:** Array of extensions that shouldn't be instrumented. Defaults to well-known static files.

For example, to use UUIDs for ID generation:

``` ruby
use Rack::Instruments, id_generator: -> { rand(36**8).to_s(36) }
```

To disable ID generation:

``` ruby
use Rack::Instruments, id_generator: nil
```

Testing
-------

    rake test
