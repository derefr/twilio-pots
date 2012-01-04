require 'sinatra'
require 'twilio-ruby'

before do
  @client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_SECRET']
end

get '/responder' do
  Twilio::TwiML::Response.new do |r|
    r.say "Hello Monkey"
  end
end
