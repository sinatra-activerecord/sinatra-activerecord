require 'spec_helper'
require 'sinatra/activerecord/rake'
require 'fileutils'

describe "Rake tasks" do
  include Sinatra::ActiveRecordTasks

  def schema_version
    ActiveRecord::Migrator.current_version
  end

  before(:each) do
    ActiveRecord::Base.remove_connection
    ActiveRecord::Base.establish_connection("sqlite3:///tmp/foo.sqlite3")
    ActiveRecord::Migrator.migrations_paths = "tmp"
  end

  around(:each) do |example|
    ActiveRecord::Migration.verbose = false
    example.run
    ActiveRecord::Migration.verbose = true
  end

  after(:each) do
    FileUtils.rm_rf("db")
  end

  it "uses ActiveRecord::Migrator.migrations_paths for the migration directory" do
    ActiveRecord::Migrator.migrations_paths = "foo"
    expect {
      create_migration("create_users")
    }.to change{Dir["foo/*"].any?}.from(false).to(true)
    expect { migrate }.to change{schema_version}
    expect { rollback }.to change{schema_version}
    FileUtils.rm_rf("foo")
  end

  describe "db:create_migration" do
    it "aborts if NAME is not specified" do
      expect { create_migration(nil) }.to raise_error
    end

    it "creates the migration file" do
      create_migration("create_users")
      migration_file = Dir["tmp/*"].first
      migration_file.should match(/\d+_create_users\.rb$/)
    end
  end

  describe "db:migrate" do
    it "aborts if connection isn't established" do
      ActiveRecord::Base.remove_connection
      expect { migrate }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    end

    it "migrates the database" do
      create_migration("create_users")
      expect { migrate }.to change{schema_version}
    end

    it "handles VERSION if specified" do
      create_migration("create_users", 1)
      create_migration("create_books", 2)
      expect { migrate(1) }.to change{schema_version}.to(1)
    end
  end

  describe "db:rollback" do
    it "aborts if connection isn't established" do
      ActiveRecord::Base.remove_connection
      expect { rollback }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    end

    it "rolls back the database" do
      create_migration("create_users")
      expect { migrate }.to change{schema_version}.from(0)
      expect { rollback }.to change{schema_version}.to(0)
    end

    it "handles STEP if specified" do
      create_migration("create_users", 1)
      create_migration("create_students", 2)
      migrate
      expect { rollback(2) }.to change{schema_version}.to(0)
    end
  end

  describe 'db:schema' do
    def schema_file
      'foo_schema.rb'
    end

    after(:each) do
      File.delete(schema_file)
    end

    describe "db:schema:dump" do
      it "should dump the schema for the current database state" do
        dump_schema(schema_file)
        File.exists?(schema_file).should be_true
      end
    end

    describe "db:schema:load" do
      it "should load the schema file " do
        # Create some tables
        ActiveRecord::Migration.class_eval do
          create_table :posts do |t|
            t.string  :title
            t.text :body
          end

          create_table :people do |t|
            t.string :first_name
            t.string :last_name
            t.string :short_name
          end
        end

        # Dump file
        dump_schema(schema_file)

        # Drop table
        begin
          ActiveRecord::Schema.drop_table('posts')
          ActiveRecord::Schema.drop_table('people')
        rescue
          nil
        end

        # Load schema
        load_schema(schema_file)

        # Expect tables to be there
        ActiveRecord::Base.connection.table_exists?('posts').should be_true
        ActiveRecord::Base.connection.table_exists?('people').should be_true
      end
    end    
  end
end
