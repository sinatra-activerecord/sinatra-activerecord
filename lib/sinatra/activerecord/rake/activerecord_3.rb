require "active_support/string_inquirer"

module Rails
  extend self

  def root
    Pathname.new(Rake.application.original_dir)
  end

  def env
    ActiveSupport::StringInquirer.new(ENV["APP_ENV"] || ENV["RACK_ENV"] || "development")
  end

  def application
    seed_loader = Object.new
    seed_loader.instance_eval do
      def load_seed
        load "db/seeds.rb"
      end
    end
    seed_loader
  end
end

# db:load_config can be overriden manually
Rake::Task["db:seed"].enhance(["db:load_config"])
Rake::Task["db:load_config"].clear

# define Rails' tasks as no-op
Rake::Task.define_task("db:environment")
Rake::Task.define_task("db:rails_env")
