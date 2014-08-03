campaign-id is id of originial tweet
donation-id is id of retweet
http://guarded-waters-5444.herokuapp.com/

TODO:
Raja - Venmo API call for payment and do DMs / Tweets
  -> update firebase state
Albert - Process payments in '/finish'
Albert - Dashboard view

Details:
Raja 
-> check if venmo oauth of donor exists
-> firebase call to get venmo oauth for the donor
-> firebase call to get venmo username of fundraiser
-> before performing venmo api call, mark as in progress
-> perform venmo api call if successful
-> after call, mark as done
-> otherwise, send dm / tweets

Albert
-> look up donations by user and act on unprocessed ones
response = firebase.get("donations", {"donor" => donor_twitter_username, "state" => "todo"})
-> before sending venmo api call, mark donation as in progress
-> send corresponding venmo api calls
-> mark donations as complete

-> implement dashboard view 