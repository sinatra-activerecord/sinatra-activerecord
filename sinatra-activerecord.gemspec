# encoding:utf-8

Gem::Specification.new do |gem|
  gem.name         = "sinatra-activerecord"
  gem.version      = "2.0.11"

  gem.description  = "Extends Sinatra with ActiveRecord helpers."
  gem.summary      = gem.description
  gem.homepage     = "http://github.com/janko-m/sinatra-activerecord"

  gem.authors      = ["Blake Mizerany", "Janko Marohnić"]
  gem.email        = "janko.marohnic@gmail.com"

  gem.license      = "MIT"

  gem.files        = Dir["lib/**/*"] + ["README.md", "LICENSE"]
  gem.require_path = "lib"
  gem.test_files   = gem.files.grep(%r{^(test|spec|features)/})

  gem.required_ruby_version = ">= 1.9.2"

  gem.add_dependency "sinatra", "~> 1.0"
  gem.add_dependency "activerecord", ">= 3.2", "< 5.0.0"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 3.1"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "appraisal"
end
