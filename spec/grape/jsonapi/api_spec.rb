# frozen_string_literal: true

require 'spec_helper'

describe Grape::JSONAPI::API do
  fixtures :people, :posts, :sections

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
        expect(last_response).to(
          be_a_failure.due_to(JSONAPI::FILTER_NOT_ALLOWED)
        )
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
        expect(last_response).to(
          be_a_failure.due_to(JSONAPI::INVALID_FILTER_VALUE)
        )
      end
    end

    describe 'sorting' do
      it 'sorts the returned records' do
        get 'people?sort=id'
        expect(response_data).to match_records(0..5).in_that_order

        get 'people?sort=-id'
        expect(response_data).to match_records(5.downto(0)).in_that_order
      end

      it 'sorts by multiple fields' do
        get 'posts?sort=body,-title'
        expect(response_data).to match_records(
          [14, 1, 10, 3, 12, 7, 4, 9, 8, 6, 5, 13, 15, 16, 17, 2, 11]
        ).in_that_order
      end

      it 'validates sort criteria' do
        get 'people?sort=foobar'
        expect(last_response).to(
          be_a_failure.due_to(JSONAPI::INVALID_SORT_CRITERIA)
        )
      end

      it 'respects sortable_fields list' do
        get 'posts?sort=id'
        expect(last_response).to(
          be_a_failure.due_to(JSONAPI::INVALID_SORT_CRITERIA)
        )
      end
    end

    describe 'including related resources' do
      it 'works with to-one relationships' do
        get 'posts?include=author'
        expect(last_response).to be_a_success
        expect(included_data).to match_records([1, 3, 4]).of_type('people')
      end

      it 'works with to-many relationships' do
        get 'people?include=posts&filter[id]=1'
        expect(last_response).to be_a_success
        expect(included_data).to match_records([1, 2, 11]).of_type('posts')
      end

      it 'allows secondary resource inclusion' do
        get 'people?include=posts.section&filter[id]=1'
        expect(last_response).to be_a_success
        expect(included_data).to match_records([1, 2, 11]).of_type('posts')
        expect(included_data).to match_records(2).of_type('sections')
      end
    end

    describe 'sparse fieldsets' do
      it 'only includes specified attributes' do
        get 'people?fields[people]=name,date-joined'
        response_data.each do |resource|
          expect(resource['attributes']).to include 'name'
          expect(resource['attributes']).to include 'date-joined'
          expect(resource['attributes']).not_to include 'email'
        end
      end

      it 'applies to included resources' do
        get 'people?include=posts&fields[posts]=title'
        included_data.each do |resource|
          expect(resource['attributes']).to include 'title'
          expect(resource['attributes']).not_to include 'body'
        end
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
      expect(last_response).to be_a_failure.due_to(JSONAPI::INVALID_RESOURCE)
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
      expect(last_response).to be_a_failure.due_to(JSONAPI::PARAM_NOT_ALLOWED)
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
      expect(last_response).to(
        be_a_failure(422).due_to(JSONAPI::VALIDATION_ERROR)
      )
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

  describe 'DELETE' do
    it 'is not allowed' do
      delete 'people', data: { type: 'people', id: '1' }
      expect(last_response).to be_a_failure(405)
      expect(Person.find(1)).not_to be_nil
    end
  end

  describe 'GET /:id' do
    it 'returns a singular resource' do
      get 'people/1'
      person = Person.find(1)
      expect(last_response).to be_a_success
      expect(response_data).to be_a_resource.with_id(1)

      attributes = response_data['attributes']
      expect(attributes['name']).to eql(person.name)
      expect(attributes['email']).to eql(person.email)
      date_joined = DateTime.parse(attributes['date-joined']).utc
      expect(date_joined).to eql(person.date_joined)
    end

    it 'allows `include` parameter' do
      get 'people/1?include=posts'
      expect(included_data).to match_records([1, 2, 11]).of_type('posts')
    end

    it 'allows sparse fieldsets' do
      get 'people/1?include=posts&fields[people]=name&fields[posts]=title'
      expect(response_data['attributes'].keys).to eql(['name'])
      included_data.each do |resource|
        expect(resource['attributes'].keys).to eql(['title'])
      end
    end
  end

  describe 'PATCH /:id' do
    let(:person) { Person.find(1) }

    it 'updates the existing entity' do
      patch 'people/1', data: {
        type: 'people',
        id: '1',
        attributes: {
          name: 'Joseph Author',
          email: 'joseph@zyx.fake'
        }
      }

      expect(last_response).to be_a_success
      expect(response_data).to be_a_resource.with_id('1')
      expect(person.name).to eql('Joseph Author')
      expect(person.email).to eql('joseph@zyx.fake')
    end

    it 'checks the payload type' do
      patch 'people/1', data: {
        type: 'posts',
        id: '1',
        attributes: { name: 'Posty McPosterson' }
      }

      expect(last_response).to be_a_failure.due_to(JSONAPI::INVALID_RESOURCE)

      patch 'people/1', data: {
        id: '1',
        attributes: { name: 'The Void' }
      }

      expect(last_response).to be_a_failure.due_to(JSONAPI::PARAM_MISSING)
    end

    it 'checks the payload ID' do
      patch 'people/1', data: {
        type: 'people',
        attributes: { name: 'No IDea' }
      }

      expect(last_response).to be_a_failure.due_to(JSONAPI::KEY_ORDER_MISMATCH)

      patch 'people/1', data: {
        type: 'people',
        id: '2',
        attributes: { name: 'McLovin' }
      }

      expect(last_response).to(
        be_a_failure.due_to(JSONAPI::KEY_NOT_INCLUDED_IN_URL)
      )
    end

    it 'validates the given attributes' do
      patch 'people/1', data: {
        type: 'people',
        id: '1',
        attributes: { foo: 'bar' }
      }

      expect(last_response).to be_a_failure.due_to(JSONAPI::PARAM_NOT_ALLOWED)
    end

    it 'allows relationships to be set' do
      patch 'people/1', data: {
        type: 'people',
        id: '1',
        relationships: {
          posts: {
            data: [
              { type: 'posts', id: '2' },
              { type: 'posts', id: '3' },
              { type: 'posts', id: '11' }
            ]
          }
        }
      }

      expect(last_response).to be_a_success
      expect(Post.find(3).author_id).to eql(1)
      expect(Post.find(1).author_id).to be_nil
    end
  end

  describe 'DELETE /:id' do
    it 'deletes the specified resource' do
      expect { Person.find(1) }.not_to raise_error
      delete 'people/1'
      expect { Person.find(1) }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
