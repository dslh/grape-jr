# frozen_string_literal: true
require_relative 'rendering'
require_relative 'resources'

module Grape
  module JSONAPI
    # A collection of helper methods used internally by JSON API endpoints.
    module Helpers
      include Rendering
      include Resources

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
          context: {},
          server_error_callbacks: []
        )
      end

      def process_request(action, options = {})
        @json_request = json_request_for(action.to_sym, options)

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
