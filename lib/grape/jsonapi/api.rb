require_relative 'relationships'

module Grape
  module JSONAPI
    # Uses the jsonapi-resources gem to provide a JSON-API compliant Grape::API.
    class API < ::Grape::API
      content_type :json, ::JSONAPI::MEDIA_TYPE

      class << self
        include Relationships

        def jsonapi_resource(model_class, options = {})
          resource model_class.name.underscore.pluralize do
            helpers { include Helpers }

            get { process_request(:index) }
            post { process_request(:create) } unless options[:read_only]

            route_param :id do
              get { process_request(:show) }
              patch { process_request(:update) } unless options[:read_only]

              add_resource_relationships(options)
            end
          end
        end
      end
    end
  end
end
