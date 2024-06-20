module ApplicationHelper
  def current?(key, path)
    key.to_s if current_page? path
  end

  def dsfr_class_for(flash_type)
    case flash_type
    when 'notice'
      'info'
    when 'error'
      'error'
    when 'alert'
      'warning'
    else
      flash_type.to_s
    end
  end
end
