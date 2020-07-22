# frozen_string_literal: true

require 'cgi'

RSpec::Matchers.define :include_param do |param|
  match do |link|
    expect(link).to include '?'
    expect(CGI.unescape(link.split('?').last)).to include param
  end
end
