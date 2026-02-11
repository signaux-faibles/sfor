# frozen_string_literal: true

module ForwardFillable
  def forward_fill(array, fill_to_end: false, fill_until_index: nil) # rubocop:disable Metrics/MethodLength
    # Forward-fill: if a period has a value and the next period doesn't, keep the value from the previous period
    # By default, stop forward-filling after the last period with actual data (don't fill to current date)
    # When fill_to_end is true, continue filling to the end of the array
    last_value = nil
    last_actual_index = fill_to_end ? array.length - 1 : array.rindex { |v| !v.nil? }
    last_actual_index = [last_actual_index, fill_until_index].compact.min

    array.map.with_index do |value, index|
      if value.nil?
        # Forward-fill only if we have a previous value and haven't passed the fill boundary
        last_value if !last_value.nil? && (last_actual_index.nil? || index <= last_actual_index)
      else
        # We have an actual value - update last_value and return this value
        last_value = value
        value
      end
    end
  end
end
