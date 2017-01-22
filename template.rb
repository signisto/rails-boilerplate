project_name = File.basename(__dir__)

run "rm Gemfile" if File.exist?("test")
run "rm README.md" if File.exist?("test")
run "rm public/favicon.ico" if File.exist?("test")
run "rm -rf test" if Dir.exist?("test")

file "Gemfile", <<-CODE
source "https://rubygems.org"

gem "rails", "~> 5.0.0", ">= 5.0.0.1"

#gem "activeadmin", git: "https://github.com/activeadmin/activeadmin"
#gem "inherited_resources", git: "https://github.com/activeadmin/inherited_resources"

gem "bcrypt"
gem "bootstrap-sass"
gem "jquery-rails"
gem "dotenv-rails"
gem "envoku"
gem "font-awesome-sass"
gem "haml"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "pg"
gem "puma"
gem "sqlite3"
gem "redis"
gem "sass-rails"
gem "sidekiq"
gem "turbolinks"
gem "uglifier"

group :development do
  gem "web-console"
  gem "listen"
  gem "spring"
  gem "spring-watcher-listen"
end

group :test do
  gem "rspec-rails"
  gem "factory_girl_rails"
end

group :development, :test do
  gem "byebug", platform: :mri
end
CODE

run "bundle binstubs puma rspec-core --force"

# Database
file 'config/database.example.yml', <<-CODE
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV['DATABASE_POOL'] || 5 %>
  timeout: 5000
  host: <%= ENV['DATABASE_HOST'] || 'localhost' %>
  port: <%= ENV['DATABASE_PORT'] || '5432' %>
  database: #{project_name}_<%= ENV['RAILS_ENV'] %>
  username: <%= ENV['DATABASE_USERNAME'] || '' %>
  password: <%= ENV['DATABASE_PASSWORD'] || '' %>
  min_messages: WARNING

spec:
  <<: &default

development:
  <<: &default

test:
  <<: &default

staging:
  <<: &default

production:
  <<: &default
CODE

initializer "omniauth", <<-CODE
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_OAUTH_CLIENT_ID'], ENV['GOOGLE_OAUTH_SECRET'], {
    hd: ENV['GOOGLE_OAUTH_ALLOWED_DOMAINS'] ? ENV['GOOGLE_OAUTH_ALLOWED_DOMAINS'].split(' ') : nil,
    prompt: 'select_account',
  }.compact
end
CODE

initializer "sidekiq", <<-CODE
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
generate :scaffold, "user", "email:string", "name:string"
generate :scaffold, "session", "user:references", "token:string"
rails_command "db:migrate"

# Assets
file "app/assets/stylesheets/app.scss", <<-CODE
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
$font-family-sans-serif: "Roboto Condensed", sans-serif;
$font-family-serif: $font-family-sans-serif;
$font-family-monospace: 'Inconsolata', 'Courier New';
$font-family-base: $font-family-sans-serif;

// Navigation
$navbar-height: 100px;
CODE

# Routes
route %Q(root to: "welcome#index")
route %Q(resources :sessions, only: [:new, :create])

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

# Create initial commit on first run
after_bundle do
  git :init
  git add: "."
  git commit: %Q(-m "Initial commit")
end
