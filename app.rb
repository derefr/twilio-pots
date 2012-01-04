require 'redis'
require 'sinatra'
require 'builder'
require 'twilio-ruby'
require 'rest-client'

configure do
  redis_uri = URI.parse(ENV["REDISTOGO_URL"] || 'redis://localhost:6379/')
  REDIS = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)
end

before do
  @client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_SECRET']
end

get '/responder' do
  @code = REDIS.blpop('code', 0).last

  RestClient.get("http://www.dialabc.com/sound/generate/index.html?pnum=#{@code}&auFormat=wavpcm8&toneLength=300&mtcontinue=Generate+DTMF+Tones")

  builder do |xml|
    xml.instruct!
    xml.Response do
      xml.Play("http://www.dialabc.com/i/cache/dtmfgen/wavpcm8.300/#{@code}.wav")
    end
  end
end
