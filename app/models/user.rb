class User < ActiveRecord::Base
  before_create :init
  # encoding: utf-8
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:google_oauth2]
  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(:email => data["email"]).first

    # Uncomment the section below if you want users to be created if they don't exist
    unless user
        user = User.create(
          name: data["name"],
          selfie_url: data["image"],
          email: data["email"],
          password: Devise.friendly_token[0,20]
        )
    end
    p 'user model'
    user
  end

  def init
    self.selfie_url = 'https://lh3.googleusercontent.com/-XdUIqdMkCWA/AAAAAAAAAAI/AAAAAAAAAAA/4252rscbv5M/photo.jpg'
    # self.name = self.email.split('@').first if (self.name =~ /\p{Han}/)
  end
end
