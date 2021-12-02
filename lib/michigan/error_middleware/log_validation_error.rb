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
        error = context[:validation_error]
        error_message = context[:validation_error_message]

        if error
          str = +"#{operation.name} could not be invoked due to a validation error."
          str << " Error: #{error_message}" if error_message

          @logger.error(str)
        end

        nil
      end
    end
  end
end

