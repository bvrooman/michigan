# frozen_string_literal: true

module Michigan
  module ErrorMiddleware
    class PropagateRequestError
      def inputs
        %i[log_request_error]
      end

      def call(_operation, context, *_args, **_kwargs)
        error = context[:request_error]
        raise error unless error.nil?
      end
    end
  end
end
