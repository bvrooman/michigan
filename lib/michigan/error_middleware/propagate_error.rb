# frozen_string_literal: true

module Michigan
  module ErrorMiddleware
    class PropagateError
      def call(_operation, context, *_args)
        error = context[:error]
        raise error unless error.nil?
      end
    end
  end
end
