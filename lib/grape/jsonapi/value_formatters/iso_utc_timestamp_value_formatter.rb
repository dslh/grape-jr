# frozen_string_literal: true

# Formats timestamps in ISO 8601, UTC, YYYY-MM-DDTHH:mm:ssZ format
class IsoUtcTimestampValueFormatter < JSONAPI::ValueFormatter
  class << self
    def format(raw_value)
      raw_value.utc.iso8601 if raw_value
    end

    def unformat(formatted)
      DateTime.iso8601 formatted unless formatted.blank?
    end
  end
end
