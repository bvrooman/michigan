# frozen_string_literal: true

module Michigan
  module ErrorMiddleware
    class PropagateValidationError
      def inputs
        %i[log_validation_error]
      end

      def call(_operation, context, *_args)
        error = context[:validation_error]
        raise error unless error.nil?
      end
    end
  end
end
