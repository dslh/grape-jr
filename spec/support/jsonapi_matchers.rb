# frozen_string_literal: true
require 'json-schema'

JSONAPI_SCHEMA = File.read("#{File.dirname __FILE__}/jsonapi_schema.json")

RSpec::Matchers.define :be_a_success do
  match do |response|
    expect(response.status).to eql 200
    JSON::Validator.validate!(
      JSONAPI_SCHEMA, response.body, fragment: '#/definitions/success'
    )
  end
end

RSpec::Matchers.define :be_an_empty_success do
  match do |response|
    expect(response.status).to eql 204
    expect(response.body).to eql('{}')
  end
end

RSpec::Matchers.define :be_a_resource do
  match do |resource|
    JSON::Validator.validate!(
      JSONAPI_SCHEMA, resource, fragment: '#/definitions/resource'
    )
  end
end

RSpec::Matchers.define :be_a_resource_collection do
  match do |response_data|
    expect(response_data).to be_an Array
    response_data.each do |resource|
      expect(resource).to be_a_resource
    end
  end
end
