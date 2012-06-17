Gem::Specification.new do |gem|
  gem.name        = "rack-instruments"
  gem.version     = "0.1.7"

  gem.author      = "Brandur"
  gem.email       = "brandur@mutelight.org"
  gem.homepage    = "https://github.com/brandur/rack-instruments"
  gem.license     = "MIT"
  gem.summary     = "Rack middleware providing extremely basic instrumentation."

  gem.files = %w{lib/rack/instruments.rb}

  gem.add_dependency "slides",    "~> 0.1"
end
