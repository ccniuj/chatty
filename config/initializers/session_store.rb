# Be sure to restart your server when you modify this file.

# Rails.application.config.session_store :cookie_store, key: '_chatty_session'
if (Rails.env.development? || Rails.env.test?)
  Rails.application.config.session_store :redis_session_store, {
    key: '_chatty_session',
    redis: {
      db: 2,
      expire_after: 120.minutes,
      # key_prefix: 'chatty:session:',
      host: 'localhost', # Redis host name, default is localhost
      port: 6379   # Redis port, default is 6379
    }
  }
else
  Rails.application.config.session_store :redis_session_store, {
    key: '_chatty_session',
    redis: {
      expire_after: 120.minutes,
      key_prefix: 'h:p5c6slr2jt5uc16egm0jahrvmb3',
      host: 'ec2-54-227-246-40.compute-1.amazonaws.com', # Redis host name, default is localhost
      port: 10929   # Redis port, default is 6379
    }
  }
end