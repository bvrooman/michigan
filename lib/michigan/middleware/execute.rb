# frozen_string_literal: true

require 'michigan/adaptor'

module Michigan
  module Middleware
    class Execute
      def inputs
        @inputs ||= %i[validation request log_request_start]
      end

      def outputs
        [:response]
      end

      class RequestError < StandardError
        attr_reader :original

        def initialize(original)
          @original = original
          super(original.message)
        end
      end

      def initialize
        @block = nil
      end

      attr_writer :block

      def call(operation, context, *_args, **_kwargs)
        return nil unless @block

        request = context[:request]
        response = request.response
        context[:response] = response

        begin
          exec = @block.call(operation.http_method, operation.url, request)
          adaptor = Adaptor.new(exec, config: operation.adaptor_config)
          response.body = adaptor.body
          response.http_code = adaptor.status
          response.body
        rescue StandardError => e
          response.error = e
          response.error_message = e.message
          response.http_code = e.status if e.respond_to?(:status)
          raise RequestError, e
        end
      end
    end
  end
end
