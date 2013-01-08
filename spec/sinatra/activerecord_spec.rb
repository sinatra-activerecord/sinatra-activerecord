require 'spec_helper'
require 'sinatra/base'
require 'sinatra/activerecord'

describe "the sinatra extension" do
  let(:database_url) { "sqlite3:///tmp/foo.sqlite3" }

  def new_sinatra_application
    Class.new(Sinatra::Base) do
      set :app_file, File.join(ROOT, "tmp/app.rb")
      register Sinatra::ActiveRecordExtension
    end
  end

  before(:each) do
    FileUtils.mkdir_p("tmp")
    FileUtils.rm_rf("tmp/foo.sqlite3")

    ActiveRecord::Base.remove_connection
    @app = new_sinatra_application
  end

  after(:each) do
    FileUtils.rm_rf("tmp")
  end

  it "exposes the database object" do
    @app.should respond_to(:database)
  end

  it "raises the proper error when trying to establish connection with a nonexisting database" do
    expect { @app.database }.to raise_error(ActiveRecord::AdapterNotSpecified)
  end

  it "establishes the database connection when set" do
    expect {
      @app.set :database, database_url
    }.to change{ActiveRecord::Base.connected?}.to(true)
    expect {
      @app.set :database, database_url
    }.to change{ActiveRecord::Base.connection.last_use}
  end

  it "can have the SQLite database in a folder" do
    @app.set :database, "sqlite3:///tmp/foo.sqlite3"
    expect { ActiveRecord::Base.connection }.to_not raise_error(SQLite3::CantOpenException)
  end

  it "accepts SQLite database URLs without the '3'" do
    @app.set :database, "sqlite:///tmp/foo.sqlite3"
    expect { ActiveRecord::Base.connection }.to_not raise_error(ActiveRecord::AdapterNotFound)
  end

  it "accepts a hash for the database" do
    expect {
      @app.set :database, {adapter: "sqlite3", database: "tmp/foo.sqlite3"}
    }.to change{ActiveRecord::Base.connected?}.to(true)
  end

  describe "database file" do
    it "accepts a filename for the database" do
      FileUtils.mkdir_p("tmp")
      FileUtils.cp("spec/fixtures/database.yml", "tmp")
      expect {
        @app.set :database_file, "database.yml"
      }.to change{ActiveRecord::Base.connected?}.to(true)
    end

    it "doesn't raise errors on missing #app_file" do
      @app.set :app_file, nil
      expect { @app.set :database_file, "database.yml" }.to_not raise_error
    end

    it "doesn't raise errors on missing file" do
      expect { @app.set :database_file, "database.yml" }.to_not raise_error
    end

    it "may contain a 'development' namespace" do
      FileUtils.mkdir_p("tmp")
      FileUtils.cp("spec/fixtures/database_with_namespace.yml", "tmp")
      expect {
        @app.set :database_file, "database_with_namespace.yml"
      }.to change{ActiveRecord::Base.connected?}.to(true)
    end
  end


  context "DATABASE_URL is set" do
    before(:all) { ENV["DATABASE_URL"] = database_url }
    after(:all) { ENV.delete("DATABASE_URL") }

    it "establishes the connection upon registering" do
      ActiveRecord::Base.remove_connection
      expect {
        @app = new_sinatra_application
      }.to change{ActiveRecord::Base.connected?}.to(true)
    end

    it "is overriden by config/database.yml" do
      FileUtils.mkdir_p("tmp/config")
      FileUtils.touch("tmp/config/database.yml")

      expect {
        @app = new_sinatra_application
      }.to raise_error(ActiveRecord::AdapterNotSpecified)
    end
  end
end
