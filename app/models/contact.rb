class Contact < ApplicationRecord
  belongs_to :establishment, foreign_key: :establishment_siret, primary_key: :siret
  include Discard::Model

  validates :email,
            format: {
              with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,
              allow_blank: true,
              message: "Saisir une adresse email valide, par exemple jean.dupont@email.fr" # rubocop:disable Rails/I18nLocaleTexts
            }
end
