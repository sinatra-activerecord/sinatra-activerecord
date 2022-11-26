# encoding:utf-8

Gem::Specification.new do |gem|
  gem.name         = "sinatra-activerecord"
  gem.version      = "2.0.26"

  gem.description  = "Extends Sinatra with ActiveRecord helpers."
  gem.summary      = gem.description
  gem.homepage     = "http://github.com/sinatra-activerecord/sinatra-activerecord"

  gem.authors      = ["Blake Mizerany", "Janko Marohnić", "Axel Kee"]
  gem.email        = "axel@rubyyagi.com"

  gem.license      = "MIT"

  gem.files        = Dir["lib/**/*"] + ["README.md", "LICENSE"]
  gem.require_path = "lib"
  gem.test_files   = gem.files.grep(%r{^(test|spec|features)/})

  gem.required_ruby_version = ">= 2.6.0"

  gem.add_dependency "sinatra", ">= 1.0"
  gem.add_dependency "activerecord", ">= 4.1"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 3.1"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "appraisal"
end
