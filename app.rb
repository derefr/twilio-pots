require 'sinatra'
require 'twilio-ruby'

get '/responder' do
  Twilio::TwiML::Response.new do |r|
    r.say "Hello Monkey"
  end
end
