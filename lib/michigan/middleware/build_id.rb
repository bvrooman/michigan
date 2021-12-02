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

      def call(_operation, context, *_args)
        context[:id] = generate_id
      end

      private

      def generate_id
        SecureRandom.uuid
      end
    end
  end
end
