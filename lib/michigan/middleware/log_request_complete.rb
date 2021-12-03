# frozen_string_literal: true

module Michigan
  module Middleware
    class LogRequestComplete
      def inputs
        %i[log_request_start request response]
      end

      def outputs
        [:log_request_complete]
      end

      def initialize
        @logger = Michigan.config.logger
      end

      def call(_operation, context, *_args)
        request = context[:request]
        response = request.response

        name = request.name
        http_code = response.http_code

        str = +"#{name} completed."
        str << " Status code: #{http_code}." if http_code

        @logger.info(str)
        nil
      end
    end
  end
end
