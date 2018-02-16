#
# This app is only used to inject different publishable keys to show the
# different sign up handling for "all-plan" and "enterprise" flows.
#

require 'bundler'
Bundler.require

enable :sessions

get '/' do
  erb :home
end

get '/all-plan' do
  publishable_key = ENV["INLINE_PUBLISHABLE_KEY_ALL_PLAN"] or
                    raise "INLINE_PUBLISHABLE_KEY_ALL_PLAN env var missing"

  erb :fake_esp_app,
      locals: {
        app_name: 'Example Single Page ESP - All Plan Flow (no trial)',
        publishable_key: publishable_key
      }
end

get '/enterprise' do
  publishable_key = ENV["INLINE_PUBLISHABLE_KEY_ENTERPRISE"] or
                    raise "INLINE_PUBLISHABLE_KEY_ENTERPRISE env var missing"

  erb :fake_esp_app,
      locals: {
        app_name: 'Example Single Page ESP - Enterprise Flow',
        publishable_key: publishable_key
      }
end
