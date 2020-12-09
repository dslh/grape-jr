# frozen_string_literal: true

# Basic formatter for floating point values, leaving nil values unconverted.
# Useful for BigDecimal, for example.
class NullableFloatValueFormatter < JSONAPI::ValueFormatter
  class << self
    def format(raw_value)
      raw_value&.to_f
    end
  end
end
