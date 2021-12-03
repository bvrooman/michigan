# frozen_string_literal: true

require 'michigan/config'

module Michigan
  module ErrorMiddleware
    class LogError
      def inputs
        []
      end

      def outputs
        [:log_error]
      end

      def initialize
        @logger = Michigan.config.logger
      end

      def call(operation, context, *_args)
        return nil if context[:error].nil?

        error = context[:error]
        error_message = error.message
        backtrace = error.backtrace.join("\n")

        str = +"#{operation.name} could not be invoked due to an internal error."
        str << " Message: \"#{error_message}\"" if error_message
        str << " Backtrace: \n#{backtrace}" if backtrace

        @logger.error(str)
        nil
      end
    end
  end
end
