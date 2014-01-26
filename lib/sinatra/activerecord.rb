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
    def database=(spec)
      set :database_spec, spec
      @database = nil
      database
    end

    def database
      @database ||= begin
        ActiveRecord::Base.logger = activerecord_logger
        ActiveRecord::Base.establish_connection(resolve_spec(database_spec))
        begin
          ActiveRecord::Base.connection
        rescue Exception => e
        end
        ActiveRecord::Base
      end
    end

    def database_file=(path)
      require 'pathname'

      return if root.nil?
      path = File.join(root, path) if Pathname.new(path).relative?

      if File.exists?(path)
        require 'yaml'
        require 'erb'

        database_hash = YAML.load(ERB.new(File.read(path)).result) || {}
        ActiveRecord::Base.configurations = database_hash

        database_hash = database_hash[environment.to_s] if database_hash[environment.to_s]

        set :database, database_hash
      end
    end

    protected

    def self.registered(app)
      app.set :activerecord_logger, Logger.new(STDOUT)
      app.set :database_spec, ENV['DATABASE_URL']
      app.set :database_file, "#{Dir.pwd}/config/database.yml"
      app.database if app.database_spec
      app.helpers ActiveRecordHelper

      # re-connect if database connection dropped
      app.before { ActiveRecord::Base.verify_active_connections! if ActiveRecord::Base.respond_to?(:verify_active_connections!) }
      app.after  { ActiveRecord::Base.clear_active_connections! }
    end

    private

    def resolve_spec(database_spec)
      if database_spec.is_a?(String)
        if database_spec =~ %r{^sqlite3?://[^/]+$}
          warn <<-MESSAGE.strip_heredoc
            It seems your database URL looks something like this: "sqlite3://<database_name>".
            This doesn't work anymore, you need to use 3 slashes, like this: "sqlite3:///<database_name>".
          MESSAGE
        end
        database_spec.sub(/^sqlite:/, "sqlite3:")
      else
        database_spec
      end
    end
  end

  register ActiveRecordExtension
end
