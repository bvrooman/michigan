# frozen_string_literal: true

require 'michigan/config'

module Michigan
  module ErrorMiddleware
    class LogValidationError
      def inputs
        []
      end

      def outputs
        [:log_validation_error]
      end

      def initialize
        @logger = Michigan.config.logger
      end

      def call(operation, context, *_args)
        return nil if context[:validation_error].nil?

        error = context[:validation_error]
        error_message = error.message
        backtrace = error.backtrace.join("\n")

        str = +"#{operation.name} could not be invoked due to a validation error."
        str << " Message: \"#{error_message}\"" if error_message
        str << " Backtrace: \n#{backtrace}" if backtrace

        @logger.error(str)
        nil
      end
    end
  end
end
