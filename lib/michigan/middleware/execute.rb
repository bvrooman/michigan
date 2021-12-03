# frozen_string_literal: true

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

      def call(operation, context, *_args)
        return nil unless @block

        request = context[:request]
        response = request.response
        context[:response] = response

        begin
          exec = @block.call(operation.class.http_method, operation.url, request)
          response.body = exec
          response.http_code =
            (exec.send(:code) if exec.respond_to?(:code)) ||
            (exec.send(:status) if exec.respond_to?(:status))
          exec
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
