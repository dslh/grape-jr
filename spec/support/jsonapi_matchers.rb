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
    expect(resource['id']).to eql(@id) if @id
    JSON::Validator.validate!(
      JSONAPI_SCHEMA, resource, fragment: '#/definitions/resource'
    )
  end

  chain :with_id do |id|
    @id = id.to_s
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
    expected_ids = expected_ids.to_a if expected_ids.respond_to? :to_a
    expected_ids = Array.wrap(expected_ids).map(&:to_s)
    expected_ids.sort! unless @ordered
    expect(ids(response_data)).to eql(expected_ids)

    true
  end

  def ids(resources)
    resources = resources.select { |r| r['type'] == @type } if @type
    resources.map { |resource| resource['id'] }.tap do |ids|
      ids.sort! unless @ordered
    end
  end

  failure_message do |response_data|
    "expected resources #{expected_ids}"\
    "#{' in that order' if @ordered}, "\
    "got #{ids(response_data)}"
  end

  # Useful if the resource list contains multiple resource types.
  chain :of_type do |type|
    @type = type
  end

  # Assert that records are returned in the expected order.
  chain :in_that_order do
    @ordered = true
  end
end
