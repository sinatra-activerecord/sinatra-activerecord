require "active_support/core_ext/string/strip"
require "pathname"
require "fileutils"

namespace :db do
  desc "Create a migration (parameters: NAME, VERSION)"
  task :create_migration do
    unless ENV["NAME"]
      puts "No NAME specified. Example usage: `rake db:create_migration NAME=create_users`"
      exit
    end

    name    = ENV["NAME"]
    version = ENV["VERSION"] || Time.now.utc.strftime("%Y%m%d%H%M%S")

    ActiveRecord::Migrator.migrations_paths.each do |directory|
      next unless File.exist?(directory)
      migration_files = Pathname(directory).children
      if duplicate = migration_files.find { |path| path.basename.to_s.include?(name) }
        puts "Another migration is already named \"#{name}\": #{duplicate}."
        exit
      end
    end

    filename = "#{version}_#{name}.rb"
    dirname  = ActiveRecord::Migrator.migrations_path
    path     = File.join(dirname, filename)

    FileUtils.mkdir_p(dirname)
    File.write path, <<-MIGRATION.strip_heredoc
      class #{name.camelize} < ActiveRecord::Migration
        def change
        end
      end
    MIGRATION

    puts path
  end
end

# The `db:create` and `db:drop` command won't work with a DATABASE_URL because
# the `db:load_config` command tries to connect to the DATABASE_URL, which either
# doesn't exist or isn't able to drop the database. Ignore loading the configs for
# these tasks if a `DATABASE_URL` is present.
if ENV.has_key? "DATABASE_URL"
  Rake::Task["db:create"].prerequisites.delete("load_config")
  Rake::Task["db:drop"].prerequisites.delete("load_config")
end
