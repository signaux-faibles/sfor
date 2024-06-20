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

      # Voir avec Josquin, déterminer ce qu'on veut dans le user en base côté Rails
      # user.email = auth.info.email
    end
  end

  def establishments_followed
    EstablishmentFollower.where(user: self).includes(:establishment)
  end
end
