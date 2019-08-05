# frozen_string_literal: true
require_relative 'rendering'

module Grape
  module JSONAPI
    # Provides access to the Rendering module in a way that is usable from the
    # scope of a rescue_from block.
    class ErrorRenderer
      include Rendering

      def initialize(env)
        @env = env
      end

      def render(error)
        rendered_content = render_errors [error]
        Rack::Response.new(
          [rendered_content.to_json],
          @status,
          'Content-Type' => ::JSONAPI::MEDIA_TYPE
        )
      end

      protected

      attr_reader :env

      def controller_class
        env['api.endpoint'].options[:for]
      end

      def status(status)
        @status =
          case status
          when String
            status.to_i
          when Symbol
            Rack::Utils.status_code(status)
          else
            status
          end
      end
    end
  end
end
