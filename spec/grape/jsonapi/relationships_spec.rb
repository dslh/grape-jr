# frozen_string_literal: true
require 'spec_helper'

describe Grape::JSONAPI::Relationships do
  def app
    Class.new(Grape::API) do
      mount People
      mount Comments
      mount Posts
      mount Vehicles
      mount Preferences
      mount Authors
      mount Tags
      mount Sections
      mount Books
    end
  end

  fixtures :people, :comments, :posts, :vehicles, :preferences, :author_details, :tags, :sections, :books

  describe 'related resource collections' do
    let(:person) { Person.find(1) }
    let(:comments) { person.comments }

    it 'returns all related resources' do
      get "people/#{person.id}/comments"
      expect(last_response).to be_a_success
      expect(response_data).to be_a_resource_collection
      expect(response_data).not_to be_empty
      expect(response_data.count).to eql(comments.count)
    end
  end

  describe 'single related resource' do
    let(:person) { Person.find(1) }
    let(:preferences) { person.preferences }

    it 'returns the related resource' do
      get "people/#{person.id}/preferences"
      expect(last_response).to be_a_success
      expect(response_data).to be_a_resource
      expect(response_data['id']).to eql(preferences.id.to_s)
      expect(response_data).to include 'attributes'
    end
  end

  describe 'singular relationships' do
    let(:person) { Person.find(1) }
    let(:preferences) { person.preferences }

    describe 'getting' do
      it 'returns the relationship' do
        get "people/#{person.id}/relationships/preferences"
        expect(last_response).to be_a_success
        expect(response_data).to be_a_resource
        expect(response_data['id']).to eql(preferences.id.to_s)
        expect(response_data).not_to include 'attributes'
      end
    end

    describe 'removing' do
      it 'is possible via PATCH' do
        patch "people/#{person.id}/relationships/preferences",
              data: nil
        expect(last_response.status).to eql 204
        expect(person.reload.preferences).to be_nil
      end

      it 'is possible via DELETE' do
        delete "people/#{person.id}/relationships/preferences"
        expect(last_response.status).to eql 204
        expect(person.reload.preferences).to be_nil
      end
    end

    describe 'updating' do
      let(:person) { Person.find(2) }
      let(:preferences) { Preferences.find(2) }

      before do
        patch "people/#{person.id}/relationships/preferences",
              data: { type: 'preferences', id: preferences.id }
      end

      it 'updates the relationship' do
        expect(person.reload.preferences).to eql(preferences)
      end

      it 'returns the relationship' do
        expect(last_response).to be_a_success
        expect(resposne_data).to be_a_resource
        expect(response_data['id']).to eql(preferences.id.to_s)
        expect(response_data).not_to include 'attributes'
      end
    end
  end

  describe 'multiple relationships' do
    describe 'getting' do
      let(:person) { Person.find(1) }
      let(:comments) { person.comments }
      let(:comment_ids) { response_data.map { |resource| resource['id'].to_i } }

      it 'returns the relationships' do
        get "people/#{person.id}/relationships/comments"
        expect(last_response).to be_a_success
        expect(response_data).to be_a_resource_collection
        comments.each do |comment|
          expect(comment_ids).to include comment.id
        end
      end
    end
  end
end
