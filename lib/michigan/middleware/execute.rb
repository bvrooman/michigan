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
        attr_reader :original, :http_code

        def initialize(original, http_code)
          @original = original
          @http_code = http_code
          super(original.message)
        end
      end

      def initialize
        @block = nil
      end

      def block=(block)
        @block = block
      end

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
          http_code = e.status if e.respond_to?(:status)

          response.error = e
          response.error_message = e.message
          response.http_code = http_code

          raise RequestError.new(e, http_code)
        end
      end
    end
  end
end
