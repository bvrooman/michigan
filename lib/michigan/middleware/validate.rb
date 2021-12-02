# frozen_string_literal: true

module Michigan
  module Middleware
    class Validate
      def inputs
        []
      end

      def outputs
        %i[validation validation_error]
      end

      def initialize(callable)
        @callable = callable
      end

      def call(_operation, context, *args)
        context[:validation] = :passed
        @callable.call(*args)
      rescue StandardError => e
        context[:validation] = :failed
        context[:validation_error] = e
        context[:validation_error_message] = e.message
        raise e
      end
    end
  end
end
