class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :omniauthable, omniauth_providers: [:openid_connect]

  has_many :establishment_followers
  has_many :establishments, through: :establishment_followers


  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.id_token = auth.credentials.id_token # store the ID token (used by logout to destroy keykloak's session)
    end
  end

  def establishments_followed
    EstablishmentFollower.where(user: self).includes(:establishment)
  end
end
