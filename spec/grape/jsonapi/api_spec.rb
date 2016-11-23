# frozen_string_literal: true
require 'spec_helper'

describe Grape::JSONAPI::API do
  fixtures :people

  def app
    People
  end

  describe 'GET' do
    it 'returns an entity listing' do
      get 'people'
      expect(last_response).to be_a_success
      expect(response_data).not_to be_empty
      expect(response_data.count).to eql(Person.count)
    end
  end

  describe 'POST' do
    let(:new_person) { Person.find(response_data['id']) }

    it 'creates a new entity' do
      post 'people', data: {
        type: 'people',
        attributes: {
          name: 'Yann Author',
          'date-joined': '2016-01-01T12:34:56Z'
        }
      }
      expect(last_response).to be_a_success(201)
      expect(response_data).to be_a_resource
      expect(new_person.name).to eql('Yann Author')
      expect(new_person.email).to be_nil
      expect(new_person.date_joined).to eql Time.iso8601 '2016-01-01T12:34:56Z'
    end

    it 'allows an ID to be specified' do
      post 'people', data: {
        type: 'people',
        id: '123',
        attributes: {
          name: 'Ann Author',
          'date-joined': Time.now.iso8601
        }
      }
      expect(last_response).to be_a_success(201)
      expect(new_person.id).to eql(123)
    end

    it 'validates the given type' do
      post 'people', data: {
        type: 'bodysnatchers',
        attributes: {
          name: 'Totally Legit Person, Honest',
          email: 'not@body.snatcher',
          'date-joined' => Time.now.iso8601
        }
      }
      expect(last_response).to be_a_failure
      expect(jsonapi_response).to contain_error(JSONAPI::INVALID_RESOURCE)
    end

    it 'validates attribute names' do
      post 'people', data: {
        type: 'people',
        attributes: {
          name: 'Some Dude',
          ceci: "n'est pas une champ valide",
          'date-joined' => Time.now.iso8601
        }
      }
      expect(last_response).to be_a_failure
      expect(jsonapi_response).to contain_error(JSONAPI::PARAM_NOT_ALLOWED)
    end

    it 'validates attribute values' do
      post 'people', data: {
        type: 'people',
        attributes: {
          name: 'Cthulhu',
          email: 'cthulhu@fth.agn',
          'date-joined' => 'the first rising of the blood moon'
        }
      }
      expect(last_response).to be_a_failure(422)
      expect(jsonapi_response).to contain_error(JSONAPI::VALIDATION_ERROR)
    end
  end

  describe 'PATCH' do
    it 'is not allowed' do
      patch 'people', data: {
        type: 'people',
        id: '1',
        attributes: {
          name: 'Jane Author'
        }
      }
      expect(last_response).to be_a_failure(405)
      expect(Person.find(1).name).to eql 'Joe Author'
    end
  end
end
