require 'sinatra/base'
require 'active_record'
require 'active_support/core_ext/hash/keys'

require 'logger'
require 'pathname'
require 'yaml'
require 'erb'

require 'active_record/database_configurations/connection_url_resolver' if Gem.loaded_specs["activerecord"].version >= Gem::Version.create('6.1')

module Sinatra
  module ActiveRecordHelper
    def database
      settings.database
    end
  end

  module ActiveRecordExtension
    def self.registered(app)
      if ENV['DATABASE_URL'] && File.exist?("#{Dir.pwd}/config/database.yml")
        path = "#{Dir.pwd}/config/database.yml"
        url = ENV['DATABASE_URL']
        source = ERB.new(File.read(path)).result
        file_spec = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(source) : YAML.load(source)
        file_spec ||= {}

        # ActiveRecord 6.1+ has moved the connection url resolver to another module
        if Gem.loaded_specs["activerecord"].version >= Gem::Version.create('6.1')
          url_spec = ActiveRecord::DatabaseConfigurations::ConnectionUrlResolver.new(url).to_hash
        else
          url_spec = ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(url).to_hash
        end
        
        # if the configuration concerns only one database, and url_spec exist, url_spec will override the same key
        # if the configuration has multiple databases (Rails 6.0+ feature), url_spec is discarded
        # Following Active Record config convention
        # https://github.com/rails/rails/blob/main/activerecord/lib/active_record/database_configurations.rb#L169
        final_spec = file_spec.keys.map do |env|
          config = file_spec[env]
          if config.is_a?(Hash) && config.all? { |_k, v| v.is_a?(Hash) }
            [env, config]
          else
            [env, config.merge(url_spec)]
          end
        end.to_h

        app.set :database, final_spec
      elsif ENV['DATABASE_URL']
        app.set :database, ENV['DATABASE_URL']
      elsif File.exist?("#{Dir.pwd}/config/database.yml")
        app.set :database_file, "#{Dir.pwd}/config/database.yml"
      end

      unless defined?(Rake) || [:test, :production].include?(app.settings.environment)
        ActiveRecord::Base.logger = Logger.new(STDOUT)
      end

      app.helpers ActiveRecordHelper

      # re-connect if database connection dropped (Rails 3 only)
      app.before do
        if ActiveRecord::VERSION::MAJOR == 3
          ActiveRecord::Base.verify_active_connections! if ActiveRecord::Base.respond_to?(:verify_active_connections!)
        end
      end
      app.after do
        if ActiveRecord::VERSION::MAJOR < 7
          ActiveRecord::Base.clear_active_connections!
        else
          ActiveRecord::Base.connection_handler.clear_active_connections!
        end
      end
    end

    def database_file=(path)
      path = File.join(root, path) if Pathname(path).relative? and root
      source = ERB.new(File.read(path)).result
      spec = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(source) : YAML.load(source)
      spec ||= {}
      set :database, spec
    end

    def database=(spec)
      if spec.is_a?(Hash) and spec.symbolize_keys[environment.to_sym]
        ActiveRecord::Base.configurations = spec.stringify_keys
        ActiveRecord::Base.establish_connection(environment.to_sym)
      elsif spec.is_a?(Hash)     
        ActiveRecord::Base.configurations = {
          environment.to_s => spec.stringify_keys
        }

        ActiveRecord::Base.establish_connection(spec.stringify_keys)
      else
        if Gem.loaded_specs["activerecord"].version >= Gem::Version.create('6.0')
          ActiveRecord::Base.configurations ||= ActiveRecord::DatabaseConfigurations.new({}).resolve(spec)
        else
          ActiveRecord::Base.configurations ||= {}
          ActiveRecord::Base.configurations[environment.to_s] = ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(spec).to_hash
        end

        ActiveRecord::Base.establish_connection(spec)
      end
    end

    def database
      ActiveRecord::Base
    end
  end

  register ActiveRecordExtension
end
