# frozen_string_literal: true
module FixtureHelpers
  FIXTURES_DIR = File.expand_path('../../fixtures', __FILE__)

  def use_fixtures(*fixtures)
    ActiveRecord::FixtureSet.create_fixtures(FIXTURES_DIR, fixtures)
  end
end
