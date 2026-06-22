class Zone < ApplicationRecord
  SUPPORT_PAGE_BODY_KEY = "support_page_body".freeze
  WATERFALL_DETECTION_MOTIFS_KEY = "waterfall_detection_motifs".freeze
  DETECTION_WIDGET_INTRO_KEY = "detection_widget_intro".freeze

  KNOWN_ZONES = [
    {
      key: SUPPORT_PAGE_BODY_KEY,
      location: "Page Support (/support)",
      description: "Corps de texte principal affiché sous le titre de la page (Markdown)."
    },
    {
      key: WATERFALL_DETECTION_MOTIFS_KEY,
      location: "Fiche entreprise (/entreprises/:siren) — section « Détection Signaux faibles »",
      description: "Texte explicatif sur les motifs de détection, affiché sous les graphiques du widget cascade (Markdown). Masqué si la zone est absente ou vide."
    },
    {
      key: DETECTION_WIDGET_INTRO_KEY,
      location: "Fiche entreprise (/entreprises/:siren) — encadré bleu du widget « Détection Signaux faibles »",
      description: "Texte d'introduction de la détection (Markdown). Placeholders disponibles : %<criticite>s (niveau de risque), %<data_date>s (date des données), %<precision>s (précision de l'alerte, selon le niveau élevé ou modéré de la liste en cours). Affiche « Contenu en cours de construction » tant que la zone n'est pas créée."
    }
  ].freeze

  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }
  validates :content, presence: true

  def self.content_for(key, fallback: nil)
    find_by(key: key)&.content.presence || fallback
  end
end
