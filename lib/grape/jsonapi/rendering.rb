# frozen_string_literal: true
module Grape
  module JSONAPI
    # A collection of internal methods used for rendering responses.
    module Rendering
      def render_errors(errors)
        operation_results = ::JSONAPI::OperationResults.new
        result = ::JSONAPI::ErrorsOperationResult.new(
          errors.first.status, errors
        )
        operation_results.add_result(result)

        render_results operation_results
      end

      def render_results(operation_results)
        response_doc = create_response_document(operation_results)

        response_status(response_doc)
        response_doc.contents
      end

      private

      def create_response_document(operation_results)
        ::JSONAPI::ResponseDocument.new(
          operation_results,
          document_request_options.merge(document_base_options).merge(
            primary_resource_klass: resource_class,
            key_formatter: ::JSONAPI.configuration.key_formatter,
            route_formatter: ::JSONAPI.configuration.route_formatter,
            resource_serializer_klass: ::JSONAPI::ResourceSerializer,
            serialization_options: {}
          )
        )
      end

      def response_status(response_doc)
        status_code = response_doc.status
        status_code = status_code.to_i if status_code.is_a? String
        status status_code
      end

      def document_request_options
        return {} unless defined? @json_request

        {
          request: @json_request,
          include_directives: @json_request.include_directives,
          fields: @json_request.fields
        }
      end

      def document_base_options
        {
          base_links: base_links,
          base_meta: base_meta,
          base_url: base_url
        }
      end

      def base_links
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
        "http#{'s' if request.ssl?}://#{request.host_with_port}"
      end
    end
  end
end
