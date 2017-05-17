require 'spec_helper'
require 'fileutils'

class ActiveRecord::Migration
  def migrate_with_quietness(*args)
    suppress_messages do
      migrate_without_quietness(*args)
    end
  end
  alias_method_chain :migrate, :quietness
end

RSpec.describe "the rake tasks" do
  before do
    require 'rake'
    require 'sinatra/activerecord/rake'

    Class.new(Sinatra::Base) do
      register Sinatra::ActiveRecordExtension
      set :database, {adapter: "sqlite3", database: "tmp/foo.sqlite3"}
    end

    FileUtils.mkdir_p "db"
    FileUtils.touch "db/seeds.rb"

    class Rake::Task
      def invoke_with_reenable
        invoke_without_reenable
        reenable
      end
      alias_method_chain :invoke, :reenable
    end
  end

  after do
    FileUtils.rm_rf "db"
  end

  it "has all the rake tasks working" do
    ENV["NAME"] = "create_users"

    Rake::Task["db:create"].invoke
    Rake::Task["db:create_migration"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:migrate:redo"].invoke
    Rake::Task["db:reset"].invoke
    Rake::Task["db:seed"].invoke

    ENV.delete("NAME")
  end
end
