# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

module OpenSSL
   module SSL
       SSLErrorWaitReadable = IO::WaitReadable
   end
end
require 'openssl'
