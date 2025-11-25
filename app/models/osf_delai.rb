class OsfDelai < ApplicationRecord
  belongs_to :establishment, foreign_key: :siret, primary_key: :siret, optional: true

  validates :siret, presence: true, length: { is: 14 }

  def self.active_dette_urssaf?(siret)
    where(siret: siret)
      .exists?(["date_echeance > ?", Date.current])
  end
end
