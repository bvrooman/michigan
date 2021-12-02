# frozen_string_literal: true

module Michigan
  module Middleware
    class BuildHeaders
      def inputs
        @inputs ||= [:id]
      end

      def outputs
        [:headers]
      end

      def initialize(callable)
        @callable = callable
      end

      def call(_operation, context, *args)
        context[:headers] = @callable.call(context, *args)
      end
    end
  end
end
