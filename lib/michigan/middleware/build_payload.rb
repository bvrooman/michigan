# frozen_string_literal: true

module Michigan
  module Middleware
    class BuildPayload
      def inputs
        @inputs ||= [:id]
      end

      def outputs
        [:payload]
      end

      def initialize(callable)
        @callable = callable
      end

      def call(_operation, context, *args, **kwargs)
        context[:payload] = @callable.call(context, *args, **kwargs)
      end
    end
  end
end
