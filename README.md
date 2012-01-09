# About

twilio-pots is a simple web service to enable the use of a [Twilio](https://www.twilio.com/) number as a regular phone number. People will be able to call the supplied number (set in the environment variable `DID_NUMBER`) and leave voicemails, or send SMS messages. Both will show up on the web service's log view. You will also receive an email message (on the address supplied in the environment variable `EMAIL_RECIPIENT`) for each voicemail or SMS received. You will be able to reply to SMS messages through the web service.

twilio-pots is designed to run on [Heroku](http://www.heroku.com/). It employs Heroku's redistogo and sendgrid addons for, respectively, the storage of received messages, and the sending of emails. All of these have free tiers on Heroku's service plan. Combining this with the free $30 of Twilio credit you receive for signing up with them ($28 after purchasing a DID number), you can leverage twilio-pots to have a phone number with *no cost whatsoever.*

# Installation and configuration

1. Sign up for [Heroku](http://www.heroku.com/), and for [Twilio](https://www.twilio.com/).
2. Purchase a Twilio phone number, local to whatever region you'll be using the phone number in, through their web interface. (This "purchase" uses your free credit, and is not a charge on your credit card.)
3. `git clone` this repository, enter its directory, and `heroku create` it.
4. On Twilio, create a TwiML app and configure it to point to http://*yourappname*.heroku.com/call and http://*yourappname*.heroku.com/sms, respectively, where *yourappname* is the name Heroku gave your app. Associate this app with the phone number you purchased.
4. `heroku addons:add redistogo`
5. `heroku addons:add sendgrid`
6. `heroku config:add TWILIO_ID=`[your Twilio API key here]
7. `heroku config:add TWILIO_SECRET=`[your Twilio API shared-secret here]
8. `heroku config:add DID_NUMBER=`[the number you purchased from Twilio here, in +1234567890 format]
9. `heroku config:add EMAIL_RECIPIENT=`[your email address]
10. Go to http://*yourappname*.heroku.com/. It should display an empty call log. Call or text the number you purchased&mdash;you should receive an email!

# Notes

Direct calling from the web service, and direct receiving of calls while viewing the service console, is not currently supported, but is planned. For now, you can make calls from the DID number through Twilio's debug console.
