# frozen_string_literal: true

module Michigan
  module Middleware
    class Validate
      def inputs
        []
      end

      def outputs
        %i[validation]
      end

      class ValidationError < StandardError
        attr_reader :original

        def initialize(original)
          @original = original
          super(original.message)
        end
      end

      def initialize(callable)
        @callable = callable
      end

      def call(_operation, context, *args)
        context[:validation] = :passed
        @callable.call(*args)
      rescue StandardError => e
        context[:validation] = :failed
        raise ValidationError, e
      end
    end
  end
end
