require 'sinatra'
require 'builder'
require 'twilio-ruby'

before do
  @client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_SECRET']
end

get '/responder' do
  builder do |xml|
    xml.instruct!
    xml.Response do
      xml.Say('Hi World')
    end
  end
end
