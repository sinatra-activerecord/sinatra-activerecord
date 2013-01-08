require 'sinatra/base'
require 'active_record'
require 'logger'
require 'active_support/core_ext/string/strip'

module Sinatra
  module ActiveRecordHelper
    def database
      settings.database
    end
  end

  module ActiveRecordExtension
    def database=(url)
      set :database_url, url
      @database = nil
      database
    end

    def database
      @database ||= begin
        ActiveRecord::Base.logger = activerecord_logger
        ActiveRecord::Base.establish_connection(resolve_spec(database_url))
        ActiveRecord::Base.connection
        ActiveRecord::Base
      end
    end

    def database_file=(path)
      require 'pathname'

      return if app_file.nil?
      path = File.join(File.dirname(app_file), path) if Pathname.new(path).relative?

      if File.exists?(path)
        require 'yaml'
        require 'erb'

        database_hash = YAML.load(ERB.new(File.read(path)).result) || {}
        environment_string = environment.to_s
        database_hash = database_hash[environment_string] if database_hash[environment_string]
        set :database, database_hash
      end
    end

    protected

    def self.registered(app)
      app.set :activerecord_logger, Logger.new(STDOUT)
      app.set :database_url, ENV['DATABASE_URL']
      app.set :database_file, "config/database.yml"
      app.database if app.database_url
      app.helpers ActiveRecordHelper

      # re-connect if database connection dropped
      app.before { ActiveRecord::Base.verify_active_connections! }
      app.after  { ActiveRecord::Base.clear_active_connections! }
    end

    private

    def resolve_spec(database_url)
      if database_url.is_a?(String)
        if database_url =~ %r{^sqlite3?://[^/]+$}
          warn <<-MESSAGE.strip_heredoc
            It seems your database URL looks something like this: "sqlite3://<database_name>".
            This doesn't work anymore, you need to use 3 slashes, like this: "sqlite3:///<database_name>".
          MESSAGE
        end
        database_url.sub(/^sqlite:/, "sqlite3:")
      else
        database_url
      end
    end
  end

  register ActiveRecordExtension
end
