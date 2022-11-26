# Sinatra ActiveRecord Extension

Extends [Sinatra](http://www.sinatrarb.com/) with extension methods and Rake
tasks for dealing with an SQL database using the
[ActiveRecord ORM](https://github.com/rails/rails/tree/master/activerecord).

![test badge](https://github.com/sinatra-activerecord/sinatra-activerecord/workflows/rspec/badge.svg)

## Requirement
ActiveRecord >= 4.1

## Setup

Put it in your `Gemfile`, along with the adapter of your database. For
simplicity, let's assume you're using SQLite:

```ruby
gem "sinatra-activerecord"
gem "sqlite3"
gem "rake"
```

Now require it in your Sinatra application, and establish the database
connection:

```ruby
# app.rb
require "sinatra/activerecord"

set :database, {adapter: "sqlite3", database: "foo.sqlite3"}
# or set :database_file, "path/to/database.yml"
```

If you have a `config/database.yml`, it will automatically be loaded, no need
to specify it. Also, in production, the `$DATABASE_URL` environment variable
will automatically be read as the database (if you haven't specified otherwise).

If both `config/database.yml` and `$DATABASE_URL` are present, the database configuration of this two will be merged, with $DATABASE_URL's variable taking precedence over database.yml (for the same variable / key).


Note: If you are using ActiveRecord 6.0 and above, and have [defined multiple databases](https://guides.rubyonrails.org/active_record_multiple_databases.html#setting-up-your-application) for the database.yml, the $DATABASE_URL configuration will be discarded, following [Active Record convention here](https://github.com/rails/rails/blob/main/activerecord/lib/active_record/database_configurations.rb#L169).


Note that in **modular** Sinatra applications you will need to first register
the extension:

```ruby
class YourApplication < Sinatra::Base
  register Sinatra::ActiveRecordExtension
end
```

Now require the rake tasks and your app in your `Rakefile`:

```ruby
# Rakefile
require "sinatra/activerecord/rake"

namespace :db do
  task :load_config do
    require "./app"
  end
end
```

In the Terminal test that it works:

```sh
$ bundle exec rake -T
rake db:create            # Create the database from DATABASE_URL or config/database.yml for the current Rails.env (use db:create:all to create all dbs in the config)
rake db:create_migration  # Create a migration (parameters: NAME, VERSION)
rake db:drop              # Drops the database using DATABASE_URL or the current Rails.env (use db:drop:all to drop all databases)
rake db:fixtures:load     # Load fixtures into the current environment's database
rake db:migrate           # Migrate the database (options: VERSION=x, VERBOSE=false)
rake db:migrate:status    # Display status of migrations
rake db:rollback          # Rolls the schema back to the previous version (specify steps w/ STEP=n)
rake db:schema:dump       # Create a db/schema.rb file that can be portably used against any DB supported by AR
rake db:schema:load       # Load a schema.rb file into the database
rake db:seed              # Load the seed data from db/seeds.rb
rake db:setup             # Create the database, load the schema, and initialize with the seed data (use db:reset to also drop the db first)
rake db:structure:dump    # Dump the database structure to db/structure.sql
rake db:version           # Retrieves the current schema version number
```

And that's it, you're all set :)

## Usage

You can create a migration:

```sh
$ bundle exec rake db:create_migration NAME=create_users
```

This will create a migration file in your migrations directory (`./db/migrate`
by default), ready for editing.

```ruby
class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
    end
  end
end
```

Now migrate the database:

```sh
$ bundle exec rake db:migrate
```

You can also write models:

```ruby
class User < ActiveRecord::Base
  validates_presence_of :name
end
```

You can put your models anywhere you want, only remember to require them if
they're in a separate file, and that they're loaded after `require "sinatra/activerecord"`.

Now everything just works:

```ruby
get '/users' do
  @users = User.all
  erb :index
end

get '/users/:id' do
  @user = User.find(params[:id])
  erb :show
end
```

A nice thing is that the `ActiveRecord::Base` class is available to
you through the `database` variable:

```ruby
if database.table_exists?('users')
  # Do stuff
else
  raise "The table 'users' doesn't exist."
end
```

## History

This gem was made in 2009 by Blake Mizerany, creator of Sinatra.

## Social

You can follow Janko on Twitter, [@jankomarohnic](http://twitter.com/jankomarohnic).
You can follow Axel on Twitter, [@soulchildpls](http://twitter.com/soulchildpls).

## License

[MIT](https://github.com/sinatra-activerecord/sinatra-activerecord/blob/master/LICENSE)
