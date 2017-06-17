project_name = File.basename(__dir__)

run "rm Gemfile" if File.exist?("Gemfile")
run "rm README.md" if File.exist?("README.md")
run "rm public/favicon.ico" if File.exist?("public/favicon.ico")
run "rm -rf test" if Dir.exist?("test")
run "rm -f config/database.yml" if File.exist?('config/database.yml')

file "Gemfile", <<-CODE
source 'https://rubygems.org'

gem 'rails', '~> 5.1.0'

gem 'bcrypt'
gem 'bootstrap-sass'
gem 'dotenv-rails'
gem 'devise'
gem 'envoku'
gem 'font-awesome-sass'
gem 'haml'
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'pg'
gem 'puma'
gem 'redis'
gem 'sass-rails'
gem 'sidekiq'
gem 'uglifier'

group :development do
  gem 'listen'
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'web-console'
end

group :test do
  gem 'factory_girl_rails'
  gem 'rspec-rails'
end

group :development, :test do
  gem 'byebug', platform: :mri
end
CODE

run "bundle binstubs puma rspec-core --force"

# Database
file 'config/database.yml', <<-CODE
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV['DATABASE_POOL'] || 5 %>
  timeout: 5000
  host: <%= ENV['DATABASE_HOST'] || 'localhost' %>
  port: <%= ENV['DATABASE_PORT'] || '5432' %>
  database: #{project_name.underscore}_<%= ENV['RAILS_ENV'] %>
  username: <%= ENV['DATABASE_USERNAME'] || '' %>
  password: <%= ENV['DATABASE_PASSWORD'] || '' %>
  min_messages: WARNING

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
CODE

initializer "omniauth.rb", <<-CODE
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_OAUTH_CLIENT_ID'], ENV['GOOGLE_OAUTH_SECRET'], {
    hd: ENV['GOOGLE_OAUTH_ALLOWED_DOMAINS'] ? ENV['GOOGLE_OAUTH_ALLOWED_DOMAINS'].split(' ') : nil,
    prompt: 'select_account',
  }.compact
end
CODE

initializer "sidekiq.rb", <<-CODE
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'], namespace: "sidekiq_#{project_name}" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'], namespace: "sidekiq_#{project_name}" }
end
CODE

file ".env", <<-CODE
RAILS_ENV=development
RACK_ENV=development

# OmniAuth
#GOOGLE_OAUTH_CLIENT_ID=""
#GOOGLE_OAUTH_SECRET=""
#GOOGLE_OAUTH_ALLOWED_DOMAINS="example.com yourdomain.com"
CODE

# Scaffolds
generate 'rspec:install'
rails_command "db:drop"
rails_command "db:create"
generate :controller, "welcome"
rails_command "db:migrate"

# Boilerplate welcome
file "app/views/welcome/index.haml", <<-CODE
<h1>Welcome to your new Rails 5 Application</h1>
<p>Generated by <a href="https://github.com/signisto/rails-boilerplate">signisto/rails-boilerplate</a></p>
<p><a href="/auth/google_oauth2" class="btn btn-primary">Login via Google</a></p>
CODE

# Assets
run 'rm app/assets/stylesheets/application.css' if File.exist?('app/assets/stylesheets/application.css')
run 'rm app/assets/stylesheets/application.scss' if File.exist?('app/assets/stylesheets/application.scss')
file "app/assets/stylesheets/application.scss", <<-CODE
@import "variables";
@import "bootstrap-sprockets";
@import "bootstrap";
@import "font-awesome-sprockets";
@import "font-awesome";

body {
  padding: 15px;
  padding-top: $navbar-height + 15px;
}
CODE
file "app/assets/stylesheets/_variables.scss", <<-CODE
// Base
$font-family-sans-serif: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif;
$font-family-serif: $font-family-sans-serif;
$font-family-monospace: 'Inconsolata', 'Courier New';
$font-family-base: $font-family-sans-serif;
CODE
run 'rm app/assets/javascripts/application.js' if File.exist?('app/assets/javascripts/application.js')
file "app/assets/javascripts/application.js", <<-CODE
//= require rails-ujs
//= require_tree .
CODE

# Routes
route %Q(get '/auth/:provider/callback', to: 'omniauth_callbacks#oauth')
route %Q(root to: "welcome#index")

# Environment
environment %Q(config.paths.add("lib", load_path: true, eager_load: true))
environment %Q(config.active_job.queue_adapter = :sidekiq)

# Procfile
file "Procfile", <<-CODE
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -q default -q mailers
CODE

# Scripts
file "script/server", <<-CODE
#!/bin/sh
foreman start

CODE
FileUtils.chmod("u=rwx,go=rx", "script/server")

# Create initial commit on first run
after_bundle do
  git :init
  git add: "."
  git commit: %Q(-m "Initial commit")

  run 'spring stop'
  run 'bundle exec rails generate devise:install'
  run 'bundle exec rails generate devise User'
  git add: '.'
  git commit: %Q(-m "Configure devise")

  run 'bundle exec rake db:migrate'
end
