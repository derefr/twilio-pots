require 'redis'
require 'sinatra'
require 'builder'
require 'twilio-ruby'

configure do
  redis_uri = URI.parse(ENV["REDISTOGO_URL"] || 'redis://localhost:6379/')
  REDIS = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)
end

before do
  @client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_SECRET']
end

get '/responder' do
  @code = REDIS.blpop('code', 0).last

  builder do |xml|
    xml.instruct!
    xml.Response do
      xml.Dial do
        xml.Number(:sendDigits => "wwww#{@code}")
      end
    end
  end
end
