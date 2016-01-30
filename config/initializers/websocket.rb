require 'plezi'
require 'pathname'
require 'redis'

ENV['PL_REDIS_URL'] = "redis://localhost:6379/0"

class ChatController

  # the index will answer '/'
  # a regular method will answer it's own name i.e. '/foo'
  def before
    @current_user = get_user
    @connections = get_connections
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
      response.close
      return false
    end

    message = {
      event: :chat,
      from: @current_user.name,
      message: data["message"],
      selfie_url: @current_user.selfie_url,
      at: Time.now,
      connections: []
    }

    broadcast :_send_message, message.to_json
  end

  def _send_message data
      response << data
  end

  def on_open
    if params[:id].nil?
      response << {event: :error, from: :system, at: Time.now, message:   "Error: cannot connect without a nickname!"}.to_json
      close
      return false
    end
    register_as params[:id]
    # notify user_id, :event_name, "string data", hash: :data, more_hash: :data
    message = {from: '', at: Time.now}
    # list = collect(:_ask_nickname)

    # if ((list.map {|n| n.downcase}) + ['admin', 'system', 'sys', 'administrator']).include? params[:id].downcase
    #   message[:event] = :error
    #   message[:message] = "The nickname '#{params[:id]}' is already taken."
    #   response << message.to_json
    #   params[:id] = false
    #   response.close
    #   return
    # end
    # message[:message] = list.empty? ? "You're the first one here." : "#{list[0..-2].join(', ')} #{list[1] ? 'and' : ''} #{list.last} #{list[1] ? 'are' : 'is'} already in the chatroom"
    message[:message] = "hello, #{@current_user.name}"
    message[:event] = :chat
    message[:selfie_url] = @current_user.selfie_url
    message[:connections] = @connections
    response << message.to_json
    message[:message] = "#{@current_user.name} joined the chatroom."
    message[:connections] = get_current_connection
    broadcast :_send_message, message.to_json
  end

  def on_close
      broadcast :_send_message, {event: :chat, from: '', at: Time.now, message: "#{params[:id]} left the chatroom."}.to_json if params[:id]
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
