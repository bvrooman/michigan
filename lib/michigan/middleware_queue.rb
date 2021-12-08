# frozen_string_literal: true

module Michigan
  class MiddlewareQueue
    attr_reader :queue

    def initialize
      @queue = []
    end

    def clear
      queue.clear
    end

    def prepend_middlewares(middlewares)
      queue.unshift(*middlewares)
    end

    def enqueue_middlewares(middlewares)
      middlewares.to_a.each do |middleware|
        enqueue_middleware(middleware)
      end
    end

    def enqueue_middleware(callable)
      queue << callable
    end

    def empty?
      queue.empty?
    end

    def execute(operation, context, *args, **kwargs)
      final = nil
      until queue.empty?
        callable = queue.shift
        result = execute_callable(callable, operation, context, *args, **kwargs)
        unless result.nil?
          context[:result] = result
          final = result
        end
      end
      final
    end

    def execute_callable(callable, operation, context, *args, **kwargs)
      context[:current_middleware] = callable
      callable.call(operation, context, *args, **kwargs)
    rescue StandardError => e
      context[:failed_middleware] = callable
      raise e
    end
  end
end
