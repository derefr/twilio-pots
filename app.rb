require 'redis'
require 'sinatra'
require 'builder'
require 'haml'
require 'twilio-ruby'
require 'rest-client'
require 'json'
require 'pony'

configure do
  redis_uri = URI.parse(ENV["REDISTOGO_URL"] || 'redis://localhost:6379/')
  REDIS = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

  Pony.options = {
    :from => 'PeripaTwilio Gateway <the@peripatwilio.heroku.com>',
    :via => :smtp,
    :via_options => {
      :address => 'smtp.sendgrid.net',
      :port => '25',
      :authentication => :plain,
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :domain => ENV['SENDGRID_DOMAIN']
    }
  }
  

end

before do
  @client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_SECRET']
end

post '/call' do
  content_type 'text/xml'
  builder do |xml|
    xml.instruct!
    xml.Response do
      xml.Say("Record a message.")
      xml.Record(:maxLength => 3600, :action => "http://peripatwilio.heroku.com/call/recorded")
    end
  end
end

post '/call/recorded' do
  REDIS.zadd('calls', Time.now.to_i, {'from' => params[:From], 'url' => params[:RecordingUrl]}.to_json)

  Pony.mail(
    :to => ENV['EMAIL_RECIPIENT'],
    :subject => "Call from #{params[:From]}",
    :html_body => "<p>A call was recorded at #{Time.now} from #{params[:From]}.</p><p>You can <a href=\"#{params[:RecordingUrl]}\">listen to a recording</a> of the call.</a></p>")

  content_type 'text/xml'
  builder do |xml|
    xml.instruct!
    xml.Response
  end
end

post '/sms' do
  REDIS.zadd('sms', Time.now.to_i, {'outgoing' => false, 'with' => params[:From], 'text' => params[:Body]}.to_json)
  REDIS.zadd('sms:senders', Time.now.to_i, params[:From])

  Pony.mail(
    :to => ENV['EMAIL_RECIPIENT'],
    :subject => "SMS message from #{params[:From]}",
    :html_body => "<p>#{params[:Body]}</p><p>(<a href=\"http://peripatwilio.heroku.com/sms/reply?to=#{URL.encode(params[:From])}\">Reply to this message</a>)</p>")

  content_type 'text/xml'
  builder do |xml|
    xml.instruct!
    xml.Response
  end
end

get '/sms/reply'
  @to = params[:to]
  haml :reply
end

get '/' do
  @msgs = REDIS.zrange('sms', 0, -1).map{ |s| JSON.parse(s) }
  @calls = REDIS.zrange('calls', 0, -1).map{ |s| JSON.parse(s) }
  @senders = REDIS.zrevrange('sms:senders', 0, -1)

  haml :home
end

post '/sms/send' do
  REDIS.zadd('sms', Time.now.to_i, {'outgoing' => true, 'with' => params[:to], 'text' => params[:text]}.to_json)

  @client.account.sms.messages.create({:from => '+16042103583', :to => params[:to], :body => params[:text]})
  
  redirect '/'
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
