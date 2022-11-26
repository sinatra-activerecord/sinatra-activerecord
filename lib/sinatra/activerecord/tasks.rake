require "active_support/core_ext/string/strip"
require "pathname"
require "fileutils"

namespace :db do
  desc "Create a migration (parameters: NAME, VERSION)"
  task :create_migration do
    ARGV.each do |a| 
      # when we run 'rake db:create_migration create_users v1',
      # rake will also run 'rake create_users' and 'rake v1'
      # to avoid rake abort, we define an empty method for these (ie: "task :create_users do ; end")
      next if a.nil?
      task a.to_sym do ; end 
    end

    unless ENV["NAME"] || ARGV[1]
      puts "No NAME specified. Example usage: `rake db:create_migration NAME=create_users`"
      exit
    end

    name    = ENV["NAME"] || ARGV[1]
    version = ENV["VERSION"] || ARGV[2] || Time.now.utc.strftime("%Y%m%d%H%M%S")

    ActiveRecord::Migrator.migrations_paths.each do |directory|
      next unless File.exist?(directory)
      migration_files = Pathname(directory).children
      if duplicate = migration_files.find { |path| path.basename.to_s.include?(name) }
        puts "Another migration is already named \"#{name}\": #{duplicate}."
        exit
      end
    end

    filename = "#{version}_#{name}.rb"
    dirname  = ActiveRecord::Migrator.migrations_paths.first
    path     = File.join(dirname, filename)
    ar_maj   = ActiveRecord::VERSION::MAJOR
    ar_min   = ActiveRecord::VERSION::MINOR
    base     = "ActiveRecord::Migration"
    base    += "[#{ar_maj}.#{ar_min}]" if ar_maj >= 5

    FileUtils.mkdir_p(dirname)
    File.write path, <<-MIGRATION.strip_heredoc
      class #{name.camelize} < #{base}
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
