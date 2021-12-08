# frozen_string_literal: true

module Michigan
  module ErrorMiddleware
    class PropagateError
      def inputs
        %i[log_error]
      end

      def call(_operation, context, *_args, **_kwargs)
        error = context[:error]
        raise error unless error.nil?
      end
    end
  end
end
