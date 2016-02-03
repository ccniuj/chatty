var websocket = NaN;
var last_msg = NaN;
var selfie_url = document.getElementById("selfie").src;
var current_user_name = $('.info').children('p').html();
var msg = {
      'event':'',
      'from':'',
      'channel':'Chatty',
      'message':'',
      'selfie_url':'',
      'at':''
    };
window.onbeforeunload = function(e) {
  //console.log('before unload');
  // Close();
  // return 'Dialog text here.';
};
var message_queue = {'public':{}, 'private':{}, 'group':{}};

function Connect() {
    websocket = new WebSocket( 
    	(window.location.protocol.indexOf('https') < 0 ? 'ws' : 'wss') +
    	 '://' + window.location.hostname + 
    	 (window.location.port == '' ? '' : (':' + window.location.port) ) +
    	  "/chatroom/"
    	);
}
function Init()
{
    Connect();
    websocket.onopen = function(e) { 
        //update_status();
        //WriteStatus({'message':'Connected :)'});
        $('.user_list').remove();
    };
    websocket.onclose = function(e) { 
      // websocket = NaN; update_status(); 
      // console.log('closed!!!');
    };
    websocket.onmessage = function(e) {
      var msg = JSON.parse(e.data);
      last_msg = msg;
      if ((msg.event == 'open') || (msg.event == 'join')) {
        msg.connections.forEach(function(e) {
          update_user_list(e);
        });
        WriteMessage(msg, 'received');        
      }
      if (msg.event == 'close') {
        delete_offline_user(msg.connections[0].user.id);
        WriteMessage(msg, 'received');
      } 
      if (msg.event == 'public') {
        if (find_active_user().channel == msg.channel) {
          WriteMessage(msg, 'received');
        } else {
          update_message_queue(msg, msg.channel);
        }
      }
      if (msg.event == 'private') {
        if (find_active_user().name == msg.from) {
          WriteMessage(msg, 'received');
        } else {
          update_message_queue(msg, msg.from);
        }
      }
    };
        // websocket.onerror = function(e) { websocket = NaN; update_status(); };
}
    function update_user_list(msg)
    {
      var sidebar = document.getElementsByClassName("sidebar-menu")[0];
      var node = document.createElement("li");
      node.className = 'treeview user_list';
      node.innerHTML = '<a href="#" id=' + 
        msg.user.id + 
        '>' +
        '<i class="fa fa-user"></i> <span>' + 
        msg.user.name + 
        '</span><i class="fa fa-circle pull-right" style="color:#3c8dbc;"></i>' +
        '</a>';
      node.style.color = '#b8c7ce';
      sidebar.appendChild(node);
    }
function delete_offline_user (user_id)
{
  $("a#" + user_id).remove();
}
function find_active_user()
{
  return {'name': $('.active').find('span').html(), 'channel': $('.active').children('a').attr('id') };
}

function update_message_queue(msg_obj, channel)
{
  var li_from = $('.treeview:contains("' + channel + '")');
  var key = '';
  
  if (msg_obj.event == 'public') {
    key = msg_obj.channel;
  } else {
    key = msg_obj.from;
  }

  if(typeof(message_queue[msg_obj.event][key])=='undefined') {
    li_from.find('i.fa-circle').last().remove();
    message_queue[msg_obj.event][key] = [msg_obj];
  } else {
    li_from.find('span.label').last().remove();
    message_queue[msg_obj.event][key].push(msg_obj);
  }

  var span = document.createElement('span');
  span.className = 'label label-primary pull-right';
  span.innerHTML = message_queue[msg_obj.event][key].length;
  li_from.children('a').append(span);
}

function update_private_message_queue(msg_obj)
{
  var li_from = $('.treeview:contains("' + msg_obj.from + '")');
  if(typeof(message_queue[msg_obj.from])=='undefined') {
    li_from.find('i.fa-circle').last().remove();
    message_queue[msg_obj.from] = [msg_obj.message];
  } else {
    li_from.find('span.label').last().remove();
    message_queue[msg_obj.from].push(msg_obj);
  }
  var span = document.createElement('span');
  span.className = 'label label-primary pull-right';
  span.innerHTML = message_queue[msg_obj.from].count;
  li_from.children('a').append(span);
}

function WriteMessage( message, message_type)
{
    var html = '<img src="' +
             message.selfie_url +
             '" alt="user image" class="online">' +
             '<p class="message">' +
             '<a href="#" class="name">' +
               '<small class="text-muted pull-right"><i class="fa fa-clock-o"></i>'+
               message.at +
               '</small>' +
               message.from +
               '</a>' +
               message.message +
             '</p>';
    var item = document.createElement("div");
    item.className = 'item';
    item.style.minHeight = '50px';
    item.innerHTML = html;
    document.getElementById("chat-box").appendChild(item);
    scroll_to_bottom();
}
function WriteStatus( message )
{
    document.getElementById("status").innerHTML = message.message;
}
function Send()
{

  msg.channel = find_active_user().channel;

  if (msg.channel=="Chatty") {
		msg.event = 'public'
	} else {
		msg.event = 'private'
	}
  msg.from = current_user_name;
  msg.message = document.getElementById("input").value;
  msg.selfie_url = selfie_url;
  msg.at = Date();
  WriteMessage(msg, 'sent');
  websocket.send(JSON.stringify(msg));
}
function Close()
{
    console.log('closd is called');
    websocket.close('1000', 'Close normally.');
}
function update_status()
{
    if(websocket)
    {
        document.getElementById("submit").value = "Send"
        document.getElementById("input").placeholder = "your message goes here"
        //document.getElementById("status").className = "connected"
    }
    else
    {
        document.getElementById("submit").value = "Connect"
        document.getElementById("input").placeholder = "your nickname"
        document.getElementById("status").className = "disconnected"
        if(last_msg.event != 'error') document.getElementById("status").innerHTML = "Please choose your nickname and join in..."
    }
}
function on_submit()
{
    if (document.getElementById("input").value == "") {
      return false;
    }

    if(websocket)
    {
        Send()
    }
    document.getElementById("input").value = ""
}
// function generate_chatbox()
// {
//     ['Juin', 'David', 'Sam'].forEach(function(entry) {
//         msg.event = 'chat';
//         msg.from = entry;
//         msg.message = 'test';
//         msg.selfie_url = 'http://pixelvulture.com/wp-content/uploads/2014/07/Selfie-Toy-Story-Woody.jpg';
//         msg.at = Date();

//         WriteMessage(msg, 'sent');
//     });
// }
function scroll_to_bottom()
{
    var scrollTo_val = $('#chat-box').prop('scrollHeight');
    $('#chat-box').slimScroll({ scrollTo: scrollTo_val, height: '410px' });
}

$.AdminLTE.tree = function (menu) {
  var _this = this;
  var animationSpeed = $.AdminLTE.options.animationSpeed;
  $(document).on('click', menu + ' li a', function (e) {
    var $this = $(this);
    $("li.active").removeClass('active');
    $this.parent("li").addClass('active');
    var title = $this.find('span').html();
    $('.box-title').html(title);
    $('.item').remove();
    drop_message_queue(find_active_user());
    $this.children('span.label').remove();
    var i_circle = document.createElement('i');
    i_circle.className = 'fa fa-circle pull-right';
    i_circle.style = "color:#3c8dbc;"
    $this.append(i_circle);
    //span.className = 'label label-primary pull-right';
    //Fix the layout in case the sidebar stretches over the height of the window
    _this.layout.fix();
  });
};

function drop_message_queue(from) {
  if (from.channel == 'Chatty') {
    msgs = message_queue['public'][from.channel];
    if (typeof(msgs) == 'undefined') {
      return false;
    } else {
    delete message_queue['public'][from.channel];
    }
  } else {
    msgs = message_queue['private'][from.name];
    if (typeof(msgs) == 'undefined') {
      return false;
    } else {
      delete message_queue['private'][from.name];
    }
  }
  msgs.forEach(function(e){
    WriteMessage(e, 'received');
  });
}

//generate_chatbox();
Init();
