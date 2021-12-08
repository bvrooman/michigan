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

      def call(_operation, context, *_args, **_kwargs)
        return nil if context[:request_error].nil?

        request = context[:request]
        name = request.name
        http_code = request.response.http_code

        error = context[:request_error]
        error_message = error.message

        str = +"#{name} failed."
        str << " Status code: #{http_code}." if http_code
        str << " Message: \"#{error_message}\"" if error_message

        @logger.error(str)
        nil
      end
    end
  end
end
