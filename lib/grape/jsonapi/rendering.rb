# frozen_string_literal: true

module Grape
  module JSONAPI
    # A collection of internal methods used for rendering responses.
    module Rendering
      include Resources

      attr_reader :response_document

      def render_errors(errors)
        setup_response_document

        result = ::JSONAPI::ErrorsOperationResult.new(
          errors.first.status, errors
        )

        response_document.add_result(result, nil)

        render_results
      end

      def render_results
        response_status
        response_document.status == 204 ? '' : response_document.contents
      end

      private

      def create_response_document
        ::JSONAPI::ResponseDocument.new(
          key_formatter: key_formatter,
          base_meta: base_meta,
          base_links: base_response_links,
          request: respond_to?(:request) ? request : nil
        )
      end

      def setup_response_document
        @response_document = create_response_document
      end

      def response_status
        status_code = response_document.status
        status_code = status_code.to_i if status_code.is_a? String
        status status_code
      end

      def base_links
        {}
      end

      def base_response_links
        {}
      end

      def base_meta
        return {} unless defined? @json_request

        if @json_request.warnings.any?
          { warnings: @json_request.warnings }
        else
          {}
        end
      end

      def base_url
        "http#{'s' if base_request.ssl?}://#{base_request.host_with_port}"
      end

      def base_request
        env['api.endpoint'].request
      end

      def key_formatter
        ::JSONAPI.configuration.key_formatter
      end

      def route_formatter
        ::JSONAPI.configuration.route_formatter
      end

      def resource_serializer_klass
        @resource_serializer_klass ||= ::JSONAPI::ResourceSerializer
      end

      def resource_serializer
        @resource_serializer ||= resource_serializer_klass.new(
          resource_class,
          include_directives: @json_request ? @json_request.include_directives : nil,
          fields: @json_request ? @json_request.fields : {},
          base_url: base_url,
          key_formatter: key_formatter,
          route_formatter: route_formatter,
          serialization_options: {},
          controller: self
        )
      end
    end
  end
end
