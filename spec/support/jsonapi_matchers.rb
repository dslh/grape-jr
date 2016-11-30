# frozen_string_literal: true
require 'json-schema'

JSONAPI_SCHEMA = File.read("#{File.dirname __FILE__}/jsonapi_schema.json")

RSpec::Matchers.define :be_a_success do |code = 200|
  match do |response|
    expect(response.status).to eql code
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

RSpec::Matchers.define :be_a_failure do |code = 400|
  match do |response|
    expect(response.status).to eql(code)
    JSON::Validator.validate!(
      JSONAPI_SCHEMA, response.body, fragment: '#/definitions/failure'
    )
  end
end

RSpec::Matchers.define :contain_error do |code|
  match do |response|
    expect(response['errors']).to include a_hash_including('code' => code)
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

# Assert that a resource collection contains exactly
# the records with the given set of ids.
RSpec::Matchers.define :match_records do |expected_ids|
  match do |response_data|
    expect(ids(response_data)).to eql(Array.wrap(expected_ids).map(&:to_s).sort)

    response_data.each { |r| expect(r['type']).to eql(@type) } if @type

    true
  end

  def ids(resources)
    resources.map { |resource| resource['id'] }.sort
  end

  failure_message do |response_data|
    "expected resources #{expected_ids}, got #{ids(response_data)}"
  end

  chain :of_type do |type|
    @type = type
  end
end

# Assert that a resource collection contains at least
# the records with the given set of ids.
RSpec::Matchers.define :include_records do |ids|
  match do |response_data|
    ids.map!(&:to_s)
    response_data.each do |resource|
      expect(ids).to include resource['id']
      expect(resource['type']).to eql(@type) if @type
    end

    true
  end

  chain :of_type do |type|
    @type = type
  end
end
