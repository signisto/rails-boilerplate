# Rails 5 Boilerplate

[Template](http://guides.rubyonrails.org/rails_application_templates.html) for quickly creating new, pre-configured Rails 5 applications.


## Install

``` shell
rails new [project] -m https://raw.githubusercontent.com/signisto/rails-boilerplate/master/template.rb
```


## Development

The quickest way to test the template is to use it to build a new test application:

``` shell
bin/generate-test-app
```


## Devise

Devise is included by default, very little configuration is required to get it running.


## Google Auth Setup

By default the app comes pre-setup to work with Google account login.

- Go to https://console.developers.google.com/apis/dashboard
- Open app or create a new one
- Ensure Google+ and Contacts APIs are enabled
- Go to credentials and generate "OAuth Client -> Web Application"
- Ensure the callback URL has this path /auth/google_oauth2/callback
- Add .env values with new ClientID and Secret
