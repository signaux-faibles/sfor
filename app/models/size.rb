class Size < ApplicationRecord
  NAMES = %w[TPE PME ETI GE].freeze

  def self.name_for_effectif(effectif)
    return if effectif.nil?

    case effectif
    when 0..9 then "TPE"
    when 10..249 then "PME"
    when 250..4999 then "ETI"
    else "GE"
    end
  end

  def self.from_effectif(effectif)
    name = name_for_effectif(effectif)
    return unless name

    find_by(name: name)
  end
end
