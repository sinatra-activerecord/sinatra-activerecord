require 'rake'

namespace :db do
  desc "create an ActiveRecord migration"
  task :create_migration do
    Sinatra::ActiveRecordTasks.create_migration(ENV["NAME"], ENV["VERSION"])
  end

  desc "migrate the database (use version with VERSION=n)"
  task :migrate do
    Sinatra::ActiveRecordTasks.migrate(ENV["VERSION"])
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

  desc "roll back the migration (use steps with STEP=n)"
  task :rollback do
    Sinatra::ActiveRecordTasks.rollback(ENV["STEP"])
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

  namespace :schema do
    desc "dump schema into file"
    task :dump do
      Sinatra::ActiveRecordTasks.dump_schema()
    end

    desc "load schema into database"
    task :load do
      Sinatra::ActiveRecordTasks.load_schema()
    end
  end
end
