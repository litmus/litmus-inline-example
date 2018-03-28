require 'bundler'
Bundler.require

abort('PUBLISHABLE_KEY env var missing') unless ENV['PUBLISHABLE_KEY']
abort('SECRET_KEY env var missing') unless ENV['SECRET_KEY']

enable :sessions

get '/' do
  erb :fake_esp_app,
      locals: {
        app_name: ENV['APP_NAME'] || 'Example Single Page ESP',
        publishable_key: ENV['PUBLISHABLE_KEY']
      }
end

post '/sign-session-jwt' do
  @payload = JSON.parse(request.body.read)
                 .merge('iat' => Time.now.to_i)

  halt 403 unless jwt_user_matches_session_user?

  JWT.encode(@payload, ENV['SECRET_KEY'], 'HS256')
end

def jwt_user_matches_session_user?
  # in a real app we must validate the user identifier against the current
  # session.
  # To save us managing real sessions for our demo, we'll instead allow faking
  # the error scenario:
  if @payload['user'].nil? || @payload['user'].end_with?('-mismatch')
    false
  else
    true
  end
end
