module Grape
  module JSONAPI
    # Methods for linking to the resource class for a controller.
    # Scopes including this module should define a controller_class method
    module Resources
      def controller_name
        controller_class.name.gsub(/::/, '/')
      end

      def resource_class
        ::JSONAPI::Resource.resource_for controller_name
      end

      def resource_name
        "#{resource_module_name}/#{resource_class.name.underscore}"
      end

      def resource_relationships
        resource_class._relationships
      end

      def resource_module_name
        controller_class.name.split(/::/)[0...-1].join('/')
      end

      def related_resource_for(relationship)
        ::JSONAPI::Resource.resource_for(
          "#{resource_module_name}/#{relationship.class_name}".underscore
        )
      end

      def related_controller_name(resource)
        "#{resource_module_name}/#{resource._type}"
      end
    end
  end
end
