# frozen_string_literal: true

module Michigan
  module Middleware
    class BuildId
      def inputs
        []
      end

      def outputs
        [:id]
      end

      def initialize(callable)
        @callable = callable
      end

      def call(_operation, context, *args, **kwargs)
        context[:id] = @callable.call(context, *args, **kwargs)
      end
    end
  end
end
