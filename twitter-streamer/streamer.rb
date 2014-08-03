require 'tweetstream'
require 'firebase'
require 'pp'
require './env' if File.exists? 'env.rb'
require 'net/http'

firebase_uri = "https://incandescent-fire-5112.firebaseio.com/"
firebase = Firebase::Client.new(firebase_uri)

admin_twitter_handle = "@SendToken"

TweetStream.configure do |config|
  config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
  config.oauth_token        = ENV['TWITTER_OAUTH_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
  config.auth_method        = :oauth
end

TweetStream::Client.new.track(admin_twitter_handle) do |status|
  
  attributes = status.instance_variable_get(:@attrs)
  puts attributes

  if (attributes[:retweeted_status].nil?)
    puts "** New campaign **"

    # Extract metadata from tweet
    fundraiser = (attributes[:user])[:screen_name]
    campaign_id = attributes[:id_str]
    timestamp = attributes[:created_at]
    text = attributes[:text]

    # Print to console
    puts "\tFundraiser: " + fundraiser
    puts "\tCampaign ID: " + campaign_id
    puts "\tTimestamp: " + timestamp
    puts "\tText:" + text

    # Add to Firebase
    response = firebase.update("campaigns/#{campaign_id}", { "fundraiser" => fundraiser, "timestamp" => timestamp, "text" => text, "campaign_id" => campaign_id })
    puts "firebase success: " + (response.success?).to_s

  else
    puts "** Retweet **"

    # Extract metadata from tweet
    retweeted_status = attributes[:retweeted_status]
    donation_id = attributes[:id_str]
    campaign_id = retweeted_status[:id_str]
    timestamp = retweeted_status[:created_at]
    donor = (attributes[:user])[:screen_name]
    fundraiser = (retweeted_status[:user])[:screen_name]
    text = retweeted_status[:text]

    # Print to console
    puts "\tDonation ID: " + donation_id
    puts "\tCampaign ID: " + campaign_id
    puts "\tTimestamp: " + timestamp
    puts "\tDonor: " + donor
    puts "\tFundraiser: " + fundraiser
    puts "\tText: " + text

    # Add to firebase
    response = firebase.update("donations/#{donation_id}", { "campaign_id" => campaign_id, "timestamp" => timestamp, "donor" => donor, "fundraiser" => fundraiser, "text" => text, "processed_state" => "todo", "donation_id" => donation_id })
    puts "firebase success: " + (response.success?).to_s

    # TODO

    donor_data = firebase.get("users/#{donor}").body
    if (donor_data.nil?)
      puts "FIRST DONATION; SEND A TWITTER DM"
    else 
      donor_venmo_token = donor_data["venmo_access_token"]
      fundraiser_venmo_userid = firebase.get("users/#{fundraiser}").body["venmo_user_id"]
      note = "Token donation to: " + text

      puts "donor_venmo_token:#{donor_venmo_token}"
      puts "fundraiser_venmo_userid:#{fundraiser_venmo_userid}"
      puts "note:#{note}"
      puts "NOT FIRST DONATION; SEND VENMO PAYMENT"

      uri = URI('https://api.venmo.com/v1/payments')
      res = Net::HTTP.post_form(uri, 'access_token' => donor_venmo_token, 'user_id' => fundraiser_venmo_userid, 'amount' => '1', 'note' => note)
      puts res.body
  end
  end
end

