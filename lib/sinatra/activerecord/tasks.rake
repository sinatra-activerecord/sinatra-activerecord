require 'rake'

namespace :db do
  desc "create the database from config/database.yml from the current Sinatra env"
  task :create do
    Sinatra::ActiveRecordTasks.create()
  end

  desc "drops the data from config/database.yml from the current Sinatra env"
  task :drop do
    Sinatra::ActiveRecordTasks.drop()
  end

  desc "load the seed data from db/seeds.rb"
  task :seed do
    Sinatra::ActiveRecordTasks.seed()
  end

  desc "create the database and load the schema"
  task :setup do
    Sinatra::ActiveRecordTasks.setup()
  end

  desc "create an ActiveRecord migration"
  task :create_migration do
    Sinatra::ActiveRecordTasks.create_migration(ENV["NAME"], ENV["VERSION"])
  end

  desc "migrate the database (use version with VERSION=n)"
  task :migrate do
    Sinatra::ActiveRecordTasks.migrate(ENV["VERSION"])
    Rake::Task["db:schema:dump"].invoke if [:sql, :ruby].include? ActiveRecord::Base.schema_format
  end

  desc "roll back the migration (use steps with STEP=n)"
  task :rollback do
    Sinatra::ActiveRecordTasks.rollback(ENV["STEP"])
    Rake::Task["db:schema:dump"].invoke if [:sql, :ruby].include? ActiveRecord::Base.schema_format
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

  namespace :test do
    task :purge do
      Sinatra::ActiveRecordTasks.with_config_environment 'test' do
        Sinatra::ActiveRecordTasks.purge()
      end
    end

    task :load => :purge do
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
      Sinatra::ActiveRecordTasks.with_config_environment 'test' do
        Sinatra::ActiveRecordTasks.load_schema()
      end
    end

    desc 'Prepare test database from development schema'
    task :prepare do
      Rake::Task["db:test:load"].invoke
    end
  end
end
