# config/initializers/form_helpers.rb

ActionView::Helpers::FormBuilder.class_eval do
  alias_method :original_check_box, :check_box

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    hidden = @template.tag(:input,
                           type: "hidden",
                           name: "#{object_name}[#{method}]",
                           value: unchecked_value
    )
    checkbox = original_check_box(method, options.merge(include_hidden: false), checked_value, unchecked_value)
    hidden + checkbox
  end
end

ActionView::Helpers::FormTagHelper.module_eval do
  def token_tag(token = nil, form_options: {})
    if !protect_against_forgery? || token == false
      ""
    else
      token ||= form_authenticity_token(form_options: form_options)
      tag(:input, type: "hidden", name: request_forgery_protection_token, value: token)
    end
  end

  def method_tag(method)
    tag(:input, type: "hidden", name: "_method", value: method.to_s)
  end
end