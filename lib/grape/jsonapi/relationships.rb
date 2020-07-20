# frozen_string_literal: true

require_relative 'resources'

module Grape
  module JSONAPI
    # Additional setup code, for declaring relationship endpoints as part of a
    # JSON API resource.
    module Relationships
      include Resources

      protected

      def controller_class
        self
      end

      def add_resource_relationships(options)
        return unless resource_relationships.any?

        resource_relationships.each do |name, relationship|
          relationship._routed = true
          declare_related_resource(name, relationship, options)
        end

        resource :relationships do
          resource_relationships.each do |name, relationship|
            declare_relationship_resource(name, relationship, options)
          end
        end
      end

      private

      def declare_related_resource(name, relationship, _options)
        resource name.to_s.dasherize do
          define_related_resource_helpers(relationship)

          if to_many?(relationship)
            get { process_request(:get_related_resources, related_params) }
          else
            get { process_request(:get_related_resource, related_params) }
          end
        end
      end

      def declare_relationship_resource(name, relationship, _options)
        resource name.to_s.dasherize do
          define_relationship_helpers(relationship)

          get { process_relationship_request(:show) }

          if mutable_relationship? relationship
            define_relationship_mutators(relationship)
          else
            forbid_relationship_mutation
          end
        end
      end

      def define_related_resource_helpers(relationship)
        define_shared_helpers(relationship)

        helpers do
          define_method(:related_params) do
            shared_resource_params.merge(
              controller: related_controller_name(related_resource),
              source: controller_name
            )
          end
        end
      end

      def mutable_relationship?(relationship)
        resource_class.mutable? &&
          relationship.resource_klass.mutable? &&
          !relationship.options[:immutable]
      end

      def define_relationship_mutators(relationship)
        patch { process_relationship_request(:update) }
        delete { process_relationship_request(:destroy) }

        post { process_relationship_request(:create) } if to_many? relationship
      end

      def forbid_relationship_mutation
        patch { forbidden_operation }
        delete { forbidden_operation }
        post { forbidden_operation }
      end

      def define_relationship_helpers(relationship)
        define_shared_helpers(relationship)

        helpers do
          define_method(:relationship_params) do
            shared_resource_params.merge(controller: controller_name)
          end

          define_method(:process_relationship_request) do |action|
            process_request("#{action}_relationship", relationship_params)
          end
        end
      end

      def define_shared_helpers(relationship)
        related_resource = related_resource_for(relationship)

        helpers do
          define_method(:relationship) { relationship }
          define_method(:related_resource) { related_resource }

          define_method(
            :shared_resource_params,
            Relationships.instance_method(:shared_resource_params)
          )
        end
      end

      def shared_resource_params
        {
          "#{resource_class._type.to_s.singularize}_id" => params[:id],
          relationship: relationship.name
        }
      end

      def to_many?(relationship)
        relationship.is_a? ::JSONAPI::Relationship::ToMany
      end
    end
  end
end
