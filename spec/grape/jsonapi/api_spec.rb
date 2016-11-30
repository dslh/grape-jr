# frozen_string_literal: true
require 'spec_helper'

describe Grape::JSONAPI::API do
  fixtures :people, :posts

  def app
    Class.new(Grape::API) do
      mount People
      mount Posts
    end
  end

  describe 'GET' do
    it 'returns an entity listing' do
      get 'people'
      expect(last_response).to be_a_success
      expect(response_data).not_to be_empty
      expect(response_data.count).to eql(Person.count)
    end

    describe 'pagination' do
      before do
        # If the number of Person records changes, these tests may
        # need to be rewritten.
        expect(Person.count).to eql(6)
      end

      shared_examples 'a paginated resource' do |per_page_param, page_param|
        it 'limits the number of resources that are returned' do
          get "people?page[#{per_page_param}]=3"
          expect(last_response).to be_a_success
          expect(response_data.count).to eql(3)

          expect(response_links).to include 'first'
          expect(response_links).not_to include 'prev'
          expect(response_links).to include 'last'
          expect(response_links).to include 'next'
          expect(response_links['next']).to eql(response_links['last'])
          expect(response_links['next']).to include_param "page[#{page_param}]"

          ids = response_data.map { |resource| resource['id'] }

          get link_path(response_links['next'])
          expect(response_links).to include 'prev'
          expect(response_links).not_to include 'next'
          expect(response_links['prev']).to eql(response_links['first'])

          expect(response_data.count).to eql(3)
          next_ids = response_data.map { |resource| resource['id'] }
          expect((ids + next_ids).uniq.count).to eql(Person.count)
        end
      end

      context 'in `paged` mode' do
        before { PersonResource.paginator :paged }
        after { PersonResource.paginator :none }

        it_behaves_like 'a paginated resource', 'size', 'number'
      end

      context 'in `offset` mode' do
        before { PersonResource.paginator :offset }
        after { PersonResource.paginator :none }

        it_behaves_like 'a paginated resource', 'limit', 'offset'
      end
    end

    describe 'filtering' do
      it 'returns exact matches' do
        get 'posts?filter[author]=1'
        expect(response_data).to match_records [1, 2, 11]

        get 'posts?filter[title]=Update%20This%20Later'
        expect(response_data).to match_records(3)

        get 'posts?filter[title]=Later'
        expect(response_data).to be_empty
      end

      it 'allows declared filters only' do
        get 'posts?filter[body]=AAAA'
        expect(last_response).to be_a_failure
        expect(jsonapi_response).to contain_error(JSONAPI::FILTER_NOT_ALLOWED)
      end

      it 'accepts multiple values' do
        get 'posts?filter[author]=1,4'
        expect(response_data).to match_records [1, 2, 11, 12, 13]
      end

      it 'combines multiple filters' do
        get 'posts?filter[ids]=1,2,3&filter[author]=1'
        expect(response_data).to match_records [1, 2]
      end

      it 'may validate the filter value' do
        get 'people?filter[name]=ab'
        expect(last_response).to be_a_failure
        expect(jsonapi_response).to contain_error(JSONAPI::INVALID_FILTER_VALUE)
      end
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
