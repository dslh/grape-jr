class IsoUtcTimestampValueFormatter < JSONAPI::ValueFormatter
  class << self
    def format(raw_value)
      raw_value.utc.iso8601 if raw_value
    end
  end
end
