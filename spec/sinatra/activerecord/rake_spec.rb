require 'spec_helper'
require 'fileutils'

module MigrationWithQuiet
  def migrate(*args)
    suppress_messages do
      super(*args)
    end
  end
end

ActiveRecord::Migration.send(:prepend, MigrationWithQuiet)

RSpec.describe "the rake tasks" do
  before do
    Class.new(Sinatra::Base) do
      register Sinatra::ActiveRecordExtension
      set :database, {adapter: "sqlite3", database: "tmp/foo.sqlite3"}
    end

    FileUtils.mkdir_p "db"
    FileUtils.touch "db/seeds.rb"

    require 'rake'
    require 'sinatra/activerecord/rake'

    module TaskWithReenable
      def invoke(*args)
        super(*args)
        reenable
      end
    end

    Rake::Task.send(:prepend, TaskWithReenable)
  end

  after do
    FileUtils.rm_rf "db"
  end

  it "has all the rake tasks working" do
    begin
      ENV["NAME"] = "create_users"

      Rake::Task["db:create"].invoke
      Rake::Task["db:create_migration"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:migrate:redo"].invoke
      Rake::Task["db:reset"].invoke
      Rake::Task["db:seed"].invoke

      ENV.delete("NAME")
    rescue SystemExit
      fail 'should not exit'
    end

    # ensure the migration file is created
    migration_file = Dir["#{FileUtils.pwd}/db/migrate/*_create_users.rb"]
    expect(migration_file).not_to be_empty

    schema_file = Dir["#{FileUtils.pwd}/db/schema.rb"]
    expect(schema_file).not_to be_empty

    seeds_file = Dir["#{FileUtils.pwd}/db/seeds.rb"]
    expect(seeds_file).not_to be_empty
  end

  it 'works with providing argument instead of named env param' do
    begin
      ARGV[1] = 'create_users'

      Rake::Task["db:create"].invoke
      Rake::Task["db:create_migration"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:migrate:redo"].invoke
      Rake::Task["db:reset"].invoke
      Rake::Task["db:seed"].invoke
    rescue SystemExit
      fail 'should not exit'
    end

    # ensure the migration file is created
    migration_file = Dir["#{FileUtils.pwd}/db/migrate/*_create_users.rb"]
    expect(migration_file).not_to be_empty

    schema_file = Dir["#{FileUtils.pwd}/db/schema.rb"]
    expect(schema_file).not_to be_empty

    seeds_file = Dir["#{FileUtils.pwd}/db/seeds.rb"]
    expect(seeds_file).not_to be_empty
  end
end
