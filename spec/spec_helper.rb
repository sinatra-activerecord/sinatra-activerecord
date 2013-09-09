begin
  require "pry"
rescue LoadError
end

ROOT = File.expand_path("../", File.dirname(__FILE__))
Dir[File.join(ROOT, "spec/support/**/*.rb")].each &method(:require)

RSpec.configure do |config|

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    FileUtils.mkdir_p("tmp")
    FileUtils.rm("tmp/foo.sqlite3") if File.exists?("tmp/foo.sqlite3")
  end

  config.after(:each) do
    FileUtils.rm_rf("tmp")
  end

  config.include Helpers
end
