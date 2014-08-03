TWITTER_CONSUMER_KEY = ENV['TWITTER_CONSUMER_KEY']
TWITTER_CONSUMER_SECRET = ENV['TWITTER_CONSUMER_SECRET']
TWITTER_CALLBACK_URL = ENV['TWITTER_CALLBACK_URL']
VENMO_CONSUMER_KEY = ENV['VENMO_CONSUMER_KEY']
VENMO_CONSUMER_SECRET = ENV['VENMO_CONSUMER_SECRET']
VENMO_CALLBACK_URL = ENV['VENMO_CALLBACK_URL']

VENMO_SCOPE = ['access_profile', 'make_payments']

get '/' do
  if session[:twitter_access_token] && session[:twitter_secret] && session[:venmo_access_token]
    "already signed up"
  else 
    send_file File.expand_path('index.html', settings.public_folder)
  end
end

get '/twitter/login' do
  consumer = OAuth::Consumer.new TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, :site => 'https://api.twitter.com'

  request_token = consumer.get_request_token :oauth_callback => TWITTER_CALLBACK_URL
  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret

  puts "request: #{session[:request_token]}, #{session[:request_token_secret]}"

  redirect request_token.authorize_url
end

get '/twitter/callback' do
  consumer = OAuth::Consumer.new TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, :site => 'https://api.twitter.com'

  puts "CALLBACK: request: #{session[:request_token]}, #{session[:request_token_secret]}"

  request_token = OAuth::RequestToken.new consumer, session[:request_token], session[:request_token_secret]
  access_token = request_token.get_access_token :oauth_verifier => params[:oauth_verifier]

  Twitter.configure do |config|
    config.consumer_key = TWITTER_CONSUMER_KEY
    config.consumer_secret = TWITTER_CONSUMER_SECRET
    config.oauth_token = access_token.token
    config.oauth_token_secret = access_token.secret
  end
  session[:twitter_access_token] = access_token.token
  session[:twitter_secret] = access_token.secret
  # "[#{Twitter.user.screen_name}] access_token: #{access_token.token}, secret: #{access_token.secret}"
  redirect '/venmo/login'
end

get '/venmo/login' do
  redirect "https://api.venmo.com/v1/oauth/authorize?client_id=#{VENMO_CONSUMER_KEY}&scope=#{VENMO_SCOPE.join(',')}"
end

get '/venmo/callback' do
  access_token = params[:access_token]
  session[:venmo_access_token] = access_token
  redirect '/finish'
end

#finish, send twitter handle, access token, and secret to firebase
# send venmo id, venmo access token, and venmo secret to firebase
get '/finish' do 
  "Twitter access token: #{session[:twitter_access_token]}, Twitter secret: #{session[:twitter_secret]}, Venmo access token: #{session[:venmo_access_token]}"
end