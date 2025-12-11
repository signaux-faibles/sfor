class OsfAp < ApplicationRecord
  belongs_to :establishment, foreign_key: :siret, primary_key: :siret, optional: true

  validates :siret, presence: true, length: { is: 14 }
  validates :siren, presence: true, length: { is: 9 }
  validates :periode, presence: true

  def self.active_activite_partielle?(siret)
    # Find the last AP entry (is_last: true) for this siret
    ap = OsfAp.where(siret: siret, is_last: true).first

    # If no entry found, no active activité partielle
    return false unless ap

    # Check if the sum of etp_autorise and etp_consomme is > 0
    total = (ap.etp_autorise.to_f + ap.etp_consomme.to_f)
    total.positive?
  end
end
