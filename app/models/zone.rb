class Zone < ApplicationRecord
  SUPPORT_PAGE_BODY_KEY = "support_page_body".freeze
  WATERFALL_DETECTION_MOTIFS_KEY = "waterfall_detection_motifs".freeze

  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }
  validates :content, presence: true

  def self.content_for(key, fallback: nil)
    find_by(key: key)&.content.presence || fallback
  end
end
