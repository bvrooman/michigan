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

      def call(_operation, context, *args)
        context[:payload] = @callable.call(context, *args)
      end
    end
  end
end
