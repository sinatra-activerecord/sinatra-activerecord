seed_loader = Class.new do
  def load_seed
    load "#{ActiveRecord::Tasks::DatabaseTasks.db_dir}/seeds.rb"
  end
end

ActiveRecord::Tasks::DatabaseTasks.tap do |config|
  config.root                   = Rake.application.original_dir
  config.env                    = ENV["APP_ENV"] || ENV["RACK_ENV"] || "development"
  config.db_dir                 = "db"
  config.migrations_paths       = ["db/migrate"]
  config.fixtures_path          = "test/fixtures"
  config.seed_loader            = seed_loader.new
  config.database_configuration = ActiveRecord::Base.configurations
end

# db:load_config can be overriden manually
Rake::Task["db:seed"].enhance(["db:load_config"])
Rake::Task["db:load_config"].clear

# define Rails' tasks as no-op
Rake::Task.define_task("db:environment")
Rake::Task["db:test:deprecated"].clear if Rake::Task.task_defined?("db:test:deprecated")
