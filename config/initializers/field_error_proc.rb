# DSFR field partials handle error styling and aria attributes explicitly.
# See README.md § Accessibility → Form field errors and `field_error_proc`.
ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  html_tag
end
