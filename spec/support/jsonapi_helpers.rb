# frozen_string_literal: true
module JsonapiHelpers
  def jsonapi_response
    @last_response ||= JSON.parse last_response.body
  end

  def response_data
    jsonapi_response['data']
  end

  def response_links
    jsonapi_response['links']
  end
end
