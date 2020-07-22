# frozen_string_literal: true

# Formats dates in ISO 8601, YYYY-mm-dd format
#
class IsoDateValueFormatter < JSONAPI::ValueFormatter
  class << self
    def format(raw_value)
      raw_value&.iso8601
    end

    def unformat(formatted)
      Date.iso8601 formatted unless formatted.blank?
    end
  end
end
