# Sinatra ActiveRecord Extension

Extends [Sinatra](http://www.sinatrarb.com/) with extension methods and Rake
tasks for dealing with an SQL database using the
[ActiveRecord ORM](https://github.com/rails/rails/tree/master/activerecord).

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
require "sinatra/activerecord"

set :database, "sqlite3:///foo.sqlite3"
```

Alternatively, you can set the database with a hash or a YAML file. Take a look at
[this wiki](https://github.com/janko-m/sinatra-activerecord/wiki/Alternative-database-setup).

Note that in **modular** Sinatra applications you will need to first register
the extension:

```ruby
class YourApplication < Sinatra::Base
  register Sinatra::ActiveRecordExtension
end
```

Now require the rake tasks and your app in your `Rakefile`:

```ruby
require "sinatra/activerecord/rake"
require "./app"
```

In the Terminal test that it works:

```sh
$ rake -T
rake db:create                     # create the database from config/database.yml from the current Sinatra env
rake db:create_migration           # create an ActiveRecord migration
rake db:drop                       # drops the data from config/database.yml from the current Sinatra env
rake db:migrate                    # migrate the database (use version with VERSION=n)
rake db:rollback                   # roll back the migration (use steps with STEP=n)
rake db:schema:dump                # dump schema into file
rake db:schema:load                # load schema into database
rake db:seed                       # load the seed data from db/seeds.rb
rake db:setup                      # create the database and load the schema
```

And that's it, you're all set :)

## Usage

You can create a migration:

```sh
$ rake db:create_migration NAME=create_users
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
$ rake db:migrate
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

You can follow me on Twitter, I'm [@jankomarohnic](http://twitter.com/jankomarohnic).

## License

[MIT](https://github.com/janko-m/sinatra-activerecord/blob/master/LICENSE)
