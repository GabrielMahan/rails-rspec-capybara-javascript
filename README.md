# How to Even Run JavaScript Tests in Rails/RSpec/Capybara

This README is a tutorial for how to get JavaScript tests running in a Rails app using [RSpec](http://rspec.info/) and [Capybara](https://github.com/jnicklas/capybara). You can also clone this repo to get a working "hello-world" Rails app with all the instructions below already done.

Capybara works with several JavaScript drivers; for me, [Poltergeist](https://github.com/teampoltergeist/poltergeist) worked best in terms of ease of installing on Mac OS X and support on [CircleCI](https://circleci.com/). Getting JavaScript tests running wasn't the hardest part: the hardest part was working with the database. Because JavaScript tests run in a separate thread, [you can't use database transactions](https://github.com/jnicklas/capybara#transactions-and-database-setup) like you can for non-JS tests. The main alternative is to use a [database cleaner](https://github.com/DatabaseCleaner/database_cleaner) to do truncation. But you only want to do truncation for JS tests, because transactions are faster. So these steps configure your tests to use truncation for JS tests and transactions for the rest.

As a caveat, I have only enough experience with these technologies to have just gotten this working. There may very well be much better ways to these things. And newer versions of technologies may cause these instructions to go out of date. Please send me a GitHub issue with any problems, or a pull request with any corrections or improvements!

## The Hello World App

The sample is set up with a Messages model that just has a single field, `text`. In development the table is seeded with a single message, `"This is the development message!"`. When you go to the root URL of the app, this message is loaded, sent to the page, and displayed via JavaScript. This ensures that our tests will only pass if both JavaScript and the database are working.

If you want to confirm that the test fails without JavaScript support, you can check out [commit 11912603](https://github.com/CodingItWrong/rails-rspec-capybara-javascript/commit/11912603dbdfb6e0970ec0128bff3d88c781f707).

## The Steps

### Install PhantomJS

The "browser" we'll be running the tests against is PhantomJS, so you will need to install version 1.9.8 or higher. There are at least three ways to do this:

* You can [download the installer](http://phantomjs.org/) directly.
* You can install it with [NPM](https://www.npmjs.com/): `npm install -g phantomjs`
* On Mac, you can install it with [Homebrew](http://brew.sh/): `brew install phantomjs`

### Add Gems

Add the following gems to the `:test` group in your `Gemfile`:

```ruby
group :test do
  ...
  gem 'poltergeist'
  gem 'database_cleaner'
end
```

* **Poltergeist** is the Capybara driver that connects to PhantomJS for JavaScript testing.
* **Database_Cleaner** is for truncating your database.

### Configure Poltergeist

In your `spec/rails_helper.rb` file, add the following `require` statements at the bottom of the other `require`s at the top:

```ruby
require 'capybara/rspec'
require 'capybara/poltergeist'
```

Then, at the very bottom of the file, outside of the `RSpec.configure` block, add:

```ruby
Capybara.javascript_driver = :poltergeist
```

As you might guess, this configures Capybara to use Poltergeist for tests that are marked as requiring JavaScript. Other tests will continue to use the main driver (Rack::Test by default).

### Configure Database_Cleaner

To configure Database_Cleaner to truncate your database *only* for JavaScript tests, add the following inside the `RSpec.configure` block at the very bottom:

```ruby
RSpec.configure do |config|
  ...
  
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

### Mark Tests as JavaScript

For any tests that need JavaScript support, add `js: true` to their `describe`/`feature` declaration:

```ruby
feature 'JavaScript messages', js: true do
  ...
end
```

Then, when you run RSpec, Capybara should run through Poltergeist/PhantomJS and your tests that require JavaScript should pass.