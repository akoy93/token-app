require 'firebase'
require 'pp'

firebase_uri = "https://incandescent-fire-5112.firebaseio.com/"
firebase = Firebase::Client.new(firebase_uri)

donor_twitter_username='politicalcoder'
response = firebase.get("donations", {"donor" => donor_twitter_username})
response.body.keys.each { |id|
  donation_data = response.body[id]
  puts "#{donation_data["donor"]} donated to #{donation_data["fundraiser"]} for [#{donation_data["text"]}]"
  puts ""
}
