# frozen_string_literal: true

# Basic formatter for floating point values.
# Useful for BigDecimal, for example.
class FloatValueFormatter < JSONAPI::ValueFormatter
  class << self
    def format(raw_value)
      # Really we just want to avoid the default behaviour
      # of calling #to_s
      raw_value.to_f
    end
  end
end
