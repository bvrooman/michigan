# frozen_string_literal: true

module Michigan
  module Middleware
    class Authenticate
      def inputs
        []
      end

      def outputs
        [:authentication]
      end

      def initialize(callable)
        @callable = callable
      end

      def call(_operation, context, *args)
        context[:authentication] = @callable.call(*args)
      end
    end
  end
end
