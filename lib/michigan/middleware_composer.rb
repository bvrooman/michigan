# frozen_string_literal: true

require 'michigan/middleware/execute'
require 'michigan/middleware/validate'
require 'michigan/middleware_queue'
require 'michigan/graph/node'

module Michigan
  class MiddlewareComposer
    attr_reader :call_queue, :error_queue

    def initialize
      @middlewares = {}
      @error_middlewares = {}
      @call_queue = MiddlewareQueue.new
      @error_queue = MiddlewareQueue.new
      @dependency_producer_map = {}
    end

    def create_dependency(middleware)
      Graph::Node.new(middleware, @dependency_producer_map)
    end

    def add_middleware(middleware)
      name = middleware.class.name
      node = create_dependency(middleware)
      set_middleware(name, node)
    end

    def add_error_middleware(middleware)
      name = middleware.class.name
      node = create_dependency(middleware)
      set_error_middleware(name, node)
    end

    def call(operation, context, *args)
      call_queue.clear
      call_queue.enqueue_middlewares(dependency_chain)
      execute(operation, context, *args)
    end

    private

    def set_middleware(name, middleware)
      @middlewares[name] = middleware
      @dependency_chain = nil # Allow `dependency_chain` to be rememoized
    end

    def set_error_middleware(name, middleware)
      @error_middlewares[name] = middleware
      @error_dependency_chain = nil # Allow `error_dependency_chain` to be rememoized
    end

    def execute(operation, context, *args)
      result = nil

      # The error queue may choose to squelch any errors that arose during normal execution and allow execution to
      # continue, or to throw an error once more.
      #
      # Squelching the error allows middleware in the error queue to enqueue or re-enqueue any desired middleware
      # back into the normal queue. This will allow the normal queue to continue with the newly enqueued
      # middleware once the error queue has completed. An example of this behaviour is implemented by the `Retry`
      # middleware.
      #
      # Any errors thrown from this queue will propagate up and prevent the resumption of the normal queue
      # execution. For example, an error may be re-raised by the `PropagateError` middleware that is intended to
      # break the execution and propagate the error back to the client code.

      until call_queue.empty?
        begin
          result = call_queue.execute(operation, context, *args)
        rescue Middleware::Validate::ValidationError => e
          context[:validation_error] = e.original
          error_queue.clear
          error_queue.enqueue_middlewares(error_dependency_chain)
          error_queue.execute(operation, context, *args)
        rescue Middleware::Execute::RequestError => e
          context[:request_error] = e.original
          error_queue.clear
          error_queue.enqueue_middlewares(error_dependency_chain)
          error_queue.execute(operation, context, *args)
        rescue StandardError => e
          context[:error] = e
          error_queue.clear
          error_queue.enqueue_middlewares(error_dependency_chain)
          error_queue.execute(operation, context, *args)
        end
      end

      result
    end

    def dependency_chain
      @dependency_chain ||= begin
        middlewares = @middlewares.values
        middlewares.each(&:prepare)
        dependency_chains = middlewares.map(&:ordered_dependencies)
        dependency_chains.sort_by!(&:length)
        dependency_chains.reverse!
        dependency_chain = dependency_chains.flatten
        dependency_chain.uniq!
        dependency_chain
      end
    end

    def error_dependency_chain
      @error_dependency_chain ||= begin
        middlewares = @error_middlewares.values
        middlewares.each(&:prepare)
        dependency_chains = middlewares.map(&:ordered_dependencies)
        dependency_chains.sort_by!(&:length)
        dependency_chains.reverse!
        dependency_chain = dependency_chains.flatten
        dependency_chain.uniq!
        dependency_chain
      end
    end
  end
end
