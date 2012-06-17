Gem::Specification.new do |gem|
  gem.name        = "rack-instruments"
  gem.version     = "0.1.4"

  gem.author      = "Brandur"
  gem.email       = "brandur@mutelight.org"
  gem.homepage    = "https://github.com/brandur/rack-instruments"
  gem.license     = "MIT"
  gem.summary     = "Rack middleware providing extremely basic instrumentation."

  gem.files = %w{lib/rack/instruments.rb}

  gem.add_dependency "scrolls-minimal", "~> 0.1"
  gem.add_dependency "uuidtools",       "~> 2.1.2"
end
