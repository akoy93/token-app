TWITTER_CONSUMER_KEY = ENV['TWITTER_CONSUMER_KEY']
TWITTER_CONSUMER_SECRET = ENV['TWITTER_CONSUMER_SECRET']
TWITTER_CALLBACK_URL = ENV['TWITTER_CALLBACK_URL']

get '/' do
  "hello"
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
  if session[:denied]
    redirect '/'
  end
  
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

  "[#{Twitter.user.screen_name}] access_token: #{access_token.token}, secret: #{access_token.secret}"
end