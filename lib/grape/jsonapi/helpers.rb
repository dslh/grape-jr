require_relative 'resources'

module Grape
  module JSONAPI
    module Helpers
      include Resources

      def controller_class
        options[:for]
      end

      def parser_params
        @parser_params ||= params.merge(controller: controller_name)
      end

      def process_request(action, options = {})
        action_parameters = ActionController::Parameters.new(
          parser_params.merge(options).merge(action: action)
        )
        @json_request = ::JSONAPI::RequestParser.new(
          action_parameters,
          context: {},
          server_error_callbacks: []
        )

        if @json_request.errors.empty?
          results = operation_dispatcher.process(@json_request.operations)
          render_results results
        else
          render_errors(@json_request.errors)
        end
      rescue ::JSONAPI::Exceptions::Error => e
        render_errors(e.errors)
      end

      def operation_dispatcher
        ::JSONAPI::OperationDispatcher.new(
          transaction: transaction_block,
          rollback: rollback_action,
          server_error_callbacks: []
        )
      end

      def transaction_block
        ->(&block) { ActiveRecord::Base.transaction { block.yield } }
      end

      def rollback_action
        ->() { fail ActiveRecord::Rollback }
      end

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
        render_options = {
          status: response_doc.status,
          json: response_doc.contents,
          content_type: ::JSONAPI::MEDIA_TYPE
        }

        if response_doc.status == :created && response_doc.contents[:data].class != Array
          render_options[:location] = response_doc.contents[:data]['links'][:self]
        end

        status_code = response_doc.status
        status_code = status_code.to_i if status_code.is_a? String
        status status_code
        response_doc.contents
      end

      def create_response_document(operation_results)
        ::JSONAPI::ResponseDocument.new(
          operation_results,
          request: @json_request,
          primary_resource_klass: resource_class,
          include_directives: @json_request&.include_directives,
          fields: @json_request&.fields,
          key_formatter: ::JSONAPI.configuration.key_formatter,
          route_formatter: ::JSONAPI.configuration.route_formatter,
          base_links: base_links,
          base_meta: base_meta,
          base_url: base_url,
          resource_serializer_klass: ::JSONAPI::ResourceSerializer,
          serialization_options: {}
        )
      end

      def base_links
        {}
      end

      def base_meta
        if @json_request&.warnings&.any?
          { warnings: @json_request.warnings }
        else
          {}
        end
      end

      def base_url
        "http#{'s' if request.ssl?}://#{request.host_with_port}"
      end

      def forbidden_operation
        render_errors [::JSONAPI::Error.new(
          code: ::JSONAPI::FORBIDDEN,
          status: :forbidden,
          title: I18n.t('jsonapi.errors.forbidden_operation.title'),
          detail: I18n.t('jsonapi.errors.forbidden_operation.detail')
        )]
      end
    end
  end
end
