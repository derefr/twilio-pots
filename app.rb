require 'redis'
require 'sinatra'
require 'builder'
require 'twilio-ruby'
require 'rest-client'
require 'json'

configure do
  redis_uri = URI.parse(ENV["REDISTOGO_URL"] || 'redis://localhost:6379/')
  REDIS = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)
end

before do
  @client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_SECRET']
end

post '/sms' do
  REDIS.zadd('sms', Time.now.to_i, {'from' => params[:From], 'text' => params[:Body]}.to_json)

  content_type 'text/xml'
  '<?xml version="1.0" encoding="UTF-8" ?><Response></Response>'
end

get '/sms' do
  content_type 'text/plain'
  REDIS.zrange('sms', 0, -1).map{ |json_str| j = JSON.parse(json_str); "#{j['from']}: #{j['text']}" }.join("\n")
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
