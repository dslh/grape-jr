# frozen_string_literal: true

require_relative 'rendering'
require_relative 'resources'

module Grape
  module JSONAPI
    # A collection of helper methods used internally by JSON API endpoints.
    # Mainly methods were copied from https://bit.ly/3ygyl5y then adjusted.
    module Helpers
      include Rendering
      include Resources

      attr_reader :jsonapi_request

      def controller_class
        env['api.endpoint'].options[:for]
      end

      def parser_params
        @parser_params ||= params.merge(controller: controller_name)
      end

      def json_request_for(action, options)
        action_parameters = ActionController::Parameters.new(
          parser_params.merge(options).merge(action: action)
        )
        ::JSONAPI::RequestParser.new(
          action_parameters,
          # define a `context` method to pass extra data to resources
          context: respond_to?(:context) ? send(:context) : {},
          key_formatter: key_formatter,
          server_error_callbacks: []
        )
      end

      def process_request(action, options = {})
        begin
          @jsonapi_request = json_request_for(action, options)

          setup_response_document
          execute_request
        rescue StandardError => e
          handle_exceptions(e)
        end

        render_results
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def execute_request
        process_operations(jsonapi_request.transactional?) do
          jsonapi_request.each(response_document) do |op|
            op.options[:serializer] = resource_serializer_klass.new(
              op.resource_klass,
              include_directives: op.options[:include_directives],
              fields: op.options[:fields],
              base_url: base_url,
              key_formatter: key_formatter,
              route_formatter: route_formatter,
              serialization_options: {},
              controller: self
            )
            op.options[:cache_serializer_output] = !::JSONAPI.configuration.resource_cache.nil?

            process_operation(op)
          end

          fail ActiveRecord::Rollback if response_document.has_errors?
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def forbidden_operation
        render_errors [::JSONAPI::Error.new(
          code: ::JSONAPI::FORBIDDEN,
          status: :forbidden,
          title: I18n.t('jsonapi.errors.forbidden_operation.title'),
          detail: I18n.t('jsonapi.errors.forbidden_operation.detail')
        )]
      end

      def process_operations(transactional, &block)
        if transactional
          ActiveRecord::Base.transaction(&block)
        else
          begin
            block.call
          rescue ActiveRecord::Rollback
            # Can't rollback without transaction, so just ignore it
          end
        end
      end

      def process_operation(operation)
        result = operation.process
        response_document.add_result(result, operation)
      end

      private

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def handle_exceptions(exeption)
        case exeption
        when ::JSONAPI::Exceptions::Error
          errors = exeption.errors
        when ActionController::ParameterMissing
          errors = ::JSONAPI::Exceptions::ParameterMissing.new(exeption.param).errors
        else
          fail exeption if ::JSONAPI.configuration.exception_class_whitelisted?(exeption)

          # Store exception for other middlewares
          request.env['action_dispatch.exception'] ||= exeption

          internal_server_error = ::JSONAPI::Exceptions::InternalServerError.new(exeption)

          Rails.logger.error do
            "Internal Server Error: #{exeption.message} #{exeption.backtrace.join("\n")}"
          end

          errors = internal_server_error.errors
        end

        response_document.add_result(::JSONAPI::ErrorsOperationResult.new(errors[0].status, errors),
                                     nil)
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
    end
  end
end
