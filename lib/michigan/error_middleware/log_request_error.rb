# frozen_string_literal: true

require 'michigan/config'

module Michigan
  module ErrorMiddleware
    class LogRequestError
      def inputs
        []
      end

      def outputs
        [:log_request_error]
      end

      def initialize
        @logger = Michigan.config.logger
      end

      def call(_operation, context, *_args)
        request = context[:request]
        response = request.response

        if response.error
          name = request.name
          http_code = response.http_code
          error_message = response.error_message

          str = +"#{name} failed."
          str << " Status code: #{http_code}." if http_code
          str << " Message: \"#{error_message}\"" if error_message

          @logger.error(str)
        end

        nil
      end
    end
  end
end

