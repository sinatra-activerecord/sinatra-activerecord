# Changelog

## Version 1.2.5

- Fix a bug with ActiveRecord 3.0.

## Version 1.2.4

- By default look for a `config/database.yml` in the root of the running process.

## Version 1.2.3

- Allow ActiveRecord 4

## Version 1.2.2

- Fix not allowing environments other than "development", "test" and "production".

## Version 1.2.1

- Fix specifying database from a file not working properly.

## Version 1.2.0

- You can now set a custom migrations directory. Take a look at
[this wiki](https://github.com/janko-m/sinatra-activerecord/wiki/Changing-the-migrations-directory).

- You can now set the database to a YAML file. Take a look at
[this wiki](https://github.com/janko-m/sinatra-activerecord/wiki/Alternative-database-setup).

## Version 1.1.2

- Users are now warned if they use SQLite URLs with 2 slashes.

## Version 1.1.1

- The `set :database` command now accepts everything that
  `ActiveRecord::Base.establish_connection` accepts. A Hash
  is one example:

```ruby
set :database, {
  adapter: "sqlite3",
  database: "db/foo.db",
  pool: 5,
  timeout: 5000
}
```

- The database is now reset whenever you specify it with `set :database`.
- The migrations are now logged just like in Rails.

## Version 1.1.0

- If no database is specified, it will try to read from the `DATABASE_URL`
  environment variable (which is often set in production). This was
  removed in 1.0.0, but now I'm bringing it back.

## Version 1.0.1

- Removed deprecation warnings when using the `#database` helper.

## Version 1.0.0

- Fixed the database not working. Sorry, I won't let it happen again.

### Changes that are NOT backwards compatible

- There is no more "default" database. Now you always have to specify
  the database you want to connect to, it doesn't default to
  `"sqlite://#{environment}.db"` anymore.

- When you're setting an SQLite database, you now have to put 3 slashes
  after `sqlite:` instead of 2. So instead of `sqlite://database.db` you
  have to write `sqlite:///database.db`. This is now a valid URL.

## Version 0.2.1 (yanked)

- The previous version was yanked, because I forgot to add the
  `db:rollback` task (I didn't figure out how to test it yet, otherwise
  I would know it was missing). This version is then actually 0.2.0.

## Version 0.2.0 (yanked)

- Added `db:rollback` rake task.

- If you're using SQLite, you can now specify the path to where
  you want your database file to be (thanks to **@mpalmer** for this). Refer to
  [this wiki](https://github.com/janko-m/sinatra-activerecord/wiki/SQLite).

- Verify connection before requests (a MySQL error which caused the
  app to disconnect from the database after some longer time).

- Clear active connections after each request.

- `activerecord` gem is now a dependency, so you don't have to specify
  it anymore. The required version is >= 3.
