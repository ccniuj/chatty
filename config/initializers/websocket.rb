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
    begin
      data = JSON.parse data
    rescue Exception => e
      response << {event: :error, message: "Unknown Error"}.to_json
      close
      return false
    end
    binding.pry
    message = {
      event: :chat,
      message: data["message"],
      from: @current_user.name,
      to: data["to"],
      selfie_url: @current_user.selfie_url,
      at: Time.now,
      connections: []
    }
    if (message[:to] == 'Chatty')
      broadcast :_send_message, message.to_json
    else
      notify(message[:to], :_send_message, message.to_json)
    end
  end

  def _send_message data
      response << data
  end

  def on_open
    # if params[:id].nil?
    #   response << {event: :error, from: :system, at: Time.now, message:   "Error: cannot connect without a nickname!"}.to_json
    #   close
    #   return false
    # end

    register_as @current_user.id
    # notify user_id, :event_name, "string data", hash: :data, more_hash: :data
    
    greeting = "你好，#{@current_user.name}！今天想聊些什麼？"
    message = {
      from:          'Chatty',
      at:            Time.now,
      message:       greeting,
      event:         :chat,
      selfie_url:    @current_user.selfie_url,
      connections:   @other_connections
    }
    response << message.to_json

    message[:message] = "#{@current_user.name}已加入對話"
    message[:connections] = @current_connection
    broadcast :_send_message, message.to_json
  end

  def on_close
    message = {
      event:         :chat,
      from:          'Chatty',
      at:            Time.now,
      message:       "#{@current_user.name}已離開對話",
      selfie_url:    @current_user.selfie_url,
      connections:   {'close' => @current_connection}
    }
    close
    p 'plezi close websocket'
    broadcast :_send_message, message.to_json
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
  protected
  def chat data
    
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