module ApplicationHelper
  def current?(key, path)
    key.to_s if current_page? path
  end
end
