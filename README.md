rack-instruments
================

Rack middleware providing extremely basic instrumentation. Idea based on [ryandotsmith/instruments](https://github.com/ryandotsmith/instruments).

After installation and configuration, two additional logging lines (sent to `$stdout`) will accompany any requests to your applications:

    instrumentation method=GET path=/ ip=74.207.253.12 id=00749e62-b8b7-11e1-8e07-123138107430 at=start
    instrumentation method=GET path=/ ip=74.207.253.12 id=00749e62-b8b7-11e1-8e07-123138107430 status=200 at=finish elapsed=1ms

The instrumentation middleware also injects a request ID into your request's environment to help log all events associated with a particular request. This can be abstracted with a logging helper:

``` ruby
helpers do
  def log(action, attrs = {}, &blk)
    Slides.log(action, attrs.merge!(id: request.env["REQUEST_ID"]), &blk)
  end
end

get "/" do
  log :get_index
end
```

A request to / will then appear on your `$stdout` with the instrumentation lines along with:

    get_index id=00749e62-b8b7-11e1-8e07-123138107430

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

Testing
-------

    rake test
