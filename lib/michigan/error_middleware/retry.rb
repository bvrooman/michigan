# frozen_string_literal: true

require 'logger'

require_relative 'propagate_error'

module Michigan
  module ErrorMiddleware
    class Retry
      def inputs
        [:log_request_error]
      end

      def outputs
        [:retries]
      end

      attr_accessor :retriable_errors, :retries, :delay

      def initialize(retriable_errors: [], retries: 3, delay: 1)
        @retriable_errors = Array(retriable_errors)
        @retries = retries
        @delay = delay
        @logger = Michigan.config.logger
      end

      def call(operation, context, *_args)
        return nil if retries <= 0

        context[:retries] ||= 0
        current_retries = context[:retries]
        error = context[:error]

        if error.nil?
          # The request succeeded
          @logger.info("Request succeeded after #{current_retries} retries.") if current_retries >= 1
          nil
        elsif (retriable_errors.include? error.class) && (current_retries < retries)
          # The request failed with a retriable error
          context[:retries] += 1
          middlewares = context[:failed_middleware].ordered_dependencies
          operation.composer.call_queue.prepend_middlewares(middlewares)
          sleep_time = delay * 2**current_retries
          @logger.warn("Request failed; retrying in #{sleep_time} second(s).")
          sleep(sleep_time)
        else
          # The request failed with a non-retriable error or the number of retries has been exhausted
          @logger.warn("Request failed after #{current_retries} retries.") if current_retries >= 1
          node = operation.composer.create_dependency(PropagateError.new)
          node.prepare
          operation.composer.error_queue.enqueue_middleware(node)
        end
      end

      private

      attr_reader :logger
    end
  end
end
