# frozen_string_literal: true
module JsonapiHelpers
  def jsonapi_response
    if @last_response != last_response
      @last_response = last_response
      @jsonapi_response = JSON.parse last_response.body
    end

    @jsonapi_response
  end

  def response_data
    jsonapi_response['data']
  end

  def response_links
    jsonapi_response['links']
  end

  def link_path(url)
    u = URI.parse(url)
    "#{u.path}?#{u.query}"
  end
end
