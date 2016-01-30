require 'plezi'
require 'pathname'
require 'redis'

ENV['PL_REDIS_URL'] = "redis://localhost:6379/0"

class ChatController

  # the index will answer '/'
  # a regular method will answer it's own name i.e. '/foo'
  def before
    @current_user = get_user
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
    broadcast :_send_message, {event: :chat, from: params[:id], message: data["message"], selfie_url: @current_user.selfie_url, at: Time.now}.to_json
  end

  def _send_message data
      response << data
  end

  def on_open
    if params[:id].nil?
      response << {event: :error, from: :system, at: Time.now, message:   "Error: cannot connect without a nickname!"}.to_json
      response.close
      return false
    end
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
    message[:message] = "hello, #{params[:id]}"
    message[:event] = :chat
    message[:selfie_url] = @current_user.selfie_url
    response << message.to_json
    message[:message] = "#{params[:id]} joined the chatroom."
    # binding.pry
    broadcast :_send_message, message.to_json
  end

  def on_close
      broadcast :_send_message, {event: :chat, from: '', at: Time.now, message: "#{params[:id]} left the chatroom."}.to_json if params[:id]
  end

  def _ask_nickname
      return params[:id]
  end

  private
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
