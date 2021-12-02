# frozen_string_literal: true

module Michigan
  module Middleware
    class LogRequestStart
      def inputs
        %i[request validation]
      end

      def outputs
        [:log_request_start]
      end

      def initialize
        @logger = Michigan.config.logger
      end

      def call(_operation, context, *_args)
        request = context[:request]
        @logger.info("#{request.name} starting...")
        nil
      end
    end
  end
end
