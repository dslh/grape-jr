# frozen_string_literal: true
require 'spec_helper'

describe Grape::JSONAPI::API do
  subject { People }
  def app
    subject
  end

  describe 'GET' do
    before { use_fixtures('people') }

    it 'returns an entity listing' do
      get 'people'
      expect(last_response).to be_a_success
      expect(response_data).not_to be_empty
      expect(response_data.count).to eql(Person.count)
    end
  end
end
