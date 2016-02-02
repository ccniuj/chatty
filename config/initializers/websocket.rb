require 'plezi'
require 'pathname'
require 'redis'

if (Rails.env.development? || Rails.env.test?)
  ENV['PL_REDIS_URL'] = "redis://localhost:6379/0"
else
  ENV['PL_REDIS_URL'] = ENV['REDIS_URL']
end

class ChatController
  @auto_dispatch = true
  Message = {
    event:         '',
    from:          '',
    channel:       '',
    at:            Time.now,
    message:       "",
    selfie_url:    "",
    connections:   []
  }
  
  # the index will answer '/'
  # a regular method will answer it's own name i.e. '/foo'
  def before
    @current_user = get_user
    @connections = get_connections
    @current_connection = get_current_connection
    @other_connections = get_connections.reject{|c|c == @current_connection.first}
  end

  def index
    response['content-type'] = 'text/html'
    render :chat
  end

  def on_message data
  end

  def _send_message data
      response << data
  end

  def on_open
    register_as @current_user.id
    
    greeting = "你好，#{@current_user.name}！今天想聊些什麼？"
    Message[:event] = "public"
    Message[:from] = "Chatty"
    Message[:message] = greeting
    Message[:selfie_url] = @current_user.selfie_url
    Message[:connections] = @other_connections

    response << Message.to_json

    Message[:message] = "#{@current_user.name}已加入對話"
    Message[:connections] = @current_connection
    broadcast :_send_message, Message.to_json
  end

  def on_close
    Message[:event] = "close"
    Message[:from] = "Chatty"
    Message[:message] = "#{@current_user.name}已離開對話"
    Message[:selfie_url] = @current_user.selfie_url
    Message[:connections] = @current_connection

    close
    p 'plezi close websocket'
    broadcast :_send_message, Message.to_json
  end

  def _ask_nickname
      return params[:id]
  end

  def get_user
    user_session = ObjectSpace.each_object(ActionDispatch::Request::Session).
      to_a.select do |session|
        session.id == cookies['_chatty_session']
      end.
      first

    values = user_session['warden.user.user.key']
    uid = values.flatten.first
    User.find(uid)
  end

  def get_connections
    connections = ObjectSpace.each_object(Plezi::Base::WSObject).to_a.map do |connection|
      {'uuid' => connection.cookies['rails_uuid'], 'user' => connection.get_user}
    end.
    uniq
  end

  def get_current_connection
    @connections ||= get_connections
    @current_user ||= get_user
    @connections.select do |connection|
      connection['user'].id == @current_user.id
    end
  end

  # event handler

  def public data
    begin
      _init_message(data)
      broadcast :_send_message, Message.to_json
    rescue Exception => e
      response << {event: :error, message: "Unknown Error"}.to_json
      close
      return false
    end
  end

  def group data
  end

  def private data
    begin
      _init_message(data)
      notify(Message[:channel], :_send_message, Message.to_json)
    rescue Exception => e
      response << {event: :error, message: "Unknown Error"}.to_json
      close
      return false
    end
  end

  private 
  def _init_message data
    Message[:event] = data["event"]
    Message[:message] = data["message"]
    Message[:from] = @current_user.name
    Message[:channel] = data["channel"]
    Message[:selfie_url] = @current_user.selfie_url
  end
end

# Using pathname extentions for setting public folder
# set up the Root object for easy path access.

# set up the Plezi service options
Root = Pathname.new(File.dirname(__FILE__)).expand_path.parent.parent

service_options = {
  # root: Root.join('public').to_s,
  # assets: Root.join('assets').to_s,
  # assets_public: '/',
  templates: Root.join('app/views/statics').to_s,
  ssl: false
}

Plezi.host service_options

route '/chatroom/(:id)', ChatController
# route '/client.js', :client