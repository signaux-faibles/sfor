# Rails adds autocomplete="off" to all hidden fields, which is invalid HTML5:
# hidden inputs must not have autocomplete="on" or "off".
#
# See README.md — section "Accessibility" for context and maintenance notes.

# Covers f.hidden_field (form builder)
module ActionView
  module Helpers
    module Tags
      class HiddenField < TextField
        def render
          super
        end
      end
    end
  end
end

# Covers hidden_field_tag and utf8_enforcer_tag
module ActionView
  module Helpers
    module FormTagHelper
      def hidden_field_tag(name, value = nil, options = {})
        text_field_tag(name, value, options.merge(type: :hidden))
      end

      def utf8_enforcer_tag
        '<input name="utf8" type="hidden" value="&#x2713;" />'.html_safe
      end
    end
  end
end
