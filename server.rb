require 'net/http'
require 'net/https'

TWITTER_CONSUMER_KEY = ENV['TWITTER_CONSUMER_KEY']
TWITTER_CONSUMER_SECRET = ENV['TWITTER_CONSUMER_SECRET']
TWITTER_CALLBACK_URL = ENV['TWITTER_CALLBACK_URL']
VENMO_CONSUMER_KEY = ENV['VENMO_CONSUMER_KEY']
VENMO_CONSUMER_SECRET = ENV['VENMO_CONSUMER_SECRET']
VENMO_CALLBACK_URL = ENV['VENMO_CALLBACK_URL']
FIREBASE_URL = ENV['FIREBASE_URL']

VENMO_SCOPE = ['access_profile', 'make_payments']

FIREBASE = Firebase::Client.new(FIREBASE_URL)

get '/' do
  if session[:twitter_access_token] && session[:twitter_secret] && session[:venmo_access_token]
    redirect '/dashboard'
  else 
    send_file File.expand_path('index.html', settings.public_folder)
  end
end

get '/twitter/login' do
  if session[:twitter_access_token] && session[:twitter_secret] && session[:venmo_access_token].nil?
    redirect '/venmo/login'
  end
  
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

  session[:twitter_access_token] = access_token.token
  session[:twitter_secret] = access_token.secret

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
  twitter_username = nil
  venmo_user_id = nil

  # get twitter username
  client = Twitter.configure do |config|
    config.consumer_key = TWITTER_CONSUMER_KEY
    config.consumer_secret = TWITTER_CONSUMER_SECRET
    config.oauth_token = session[:twitter_access_token]
    config.oauth_token_secret = session[:twitter_secret]
  end

  #twitter username:
  twitter_username = client.user.screen_name

  # get venmo user id
  uri = URI("https://api.venmo.com/v1/me?access_token=#{session[:venmo_access_token]}")
  Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
    request = Net::HTTP::Get.new uri
    response = http.request request # Net::HTTPResponse object

    # venmo user id
    venmo_user_id = JSON.parse(response.body)['data']['user']['id']
  end

  unless session[:venmo_access_token].nil? || session[:twitter_access_token].nil? || session[:twitter_secret].nil?
    response = FIREBASE.update("users/#{twitter_username}", {"venmo_user_id" => venmo_user_id, \
        "venmo_access_token" => session[:venmo_access_token], "twitter_access_token" => session[:twitter_access_token], \
        "twitter_secret" => session[:twitter_secret]})

    puts (response.success?).to_s
  end

  # process pending donations
  response = FIREBASE.get("donations", {})
  if response.success?
    response.body.select { |k,v| v['donor'] == twiter_username && v['processed_state'] == 'todo'}.each do |k,v|
      FIREBASE.update("donations/#{k}", {'processed_state' => 'in_progress'})

      # get donor data for venmo payment
      donor_data = firebase.get("users/#{twitter_username}").body
      if (donor_data.nil?)
        FIREBASE.update("donations/#{k}", {'processed_state' => 'todo'})
      else 
        donor_venmo_token = donor_data["venmo_access_token"]
        fundraiser_venmo_userid = FIREBASE.get("users/#{v['fundraiser']}").body["venmo_user_id"]
        note = "Token donation to: " + v['text']
        puts "donor_venmo_token:#{donor_venmo_token}"
        puts "fundraiser_venmo_userid:#{fundraiser_venmo_userid}"
        puts "note:#{note}"
        puts "NOT FIRST DONATION; SEND VENMO PAYMENT"
        uri = URI('https://api.venmo.com/v1/payments')
        res = Net::HTTP.post_form(uri, 'access_token' => donor_venmo_token, 'user_id' => fundraiser_venmo_userid, 'amount' => '1', 'note' => note)
        puts res.body
      end

      FIREBASE.update("donations/#{k}", {'processed_state' => 'done'})
    end
  end

  puts "Twitter access token: #{session[:twitter_access_token]}, Twitter secret: \
      #{session[:twitter_secret]}, Venmo access token: #{session[:venmo_access_token]}"
  redirect '/dashboard'
end

get '/dashboard' do
  "dashboard"
end