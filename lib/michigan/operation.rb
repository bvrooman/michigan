# frozen_string_literal: true

require_relative 'config'

require_relative 'middleware_composer'

require_relative 'middleware/authenticate'
require_relative 'middleware/build_headers'
require_relative 'middleware/build_id'
require_relative 'middleware/build_payload'
require_relative 'middleware/build_request'
require_relative 'middleware/execute'
require_relative 'middleware/log_request_complete'
require_relative 'middleware/log_request_start'
require_relative 'middleware/validate'

require_relative 'error_middleware/log_error'
require_relative 'error_middleware/log_request_error'
require_relative 'error_middleware/log_validation_error'
require_relative 'error_middleware/propagate_error'
require_relative 'error_middleware/propagate_request_error'
require_relative 'error_middleware/propagate_validation_error'
require_relative 'error_middleware/retry'

module Michigan
  # Base class for resource operation wrappers
  class Operation
    class << self
      attr_accessor :http_method, :base_url,
                    :retries, :retriable_errors, :retry_delay

      def inherited(subclass)
        super
        subclass.http_method = http_method
        subclass.base_url = base_url
        subclass.retries = retries
        subclass.retriable_errors = retriable_errors
        subclass.retry_delay = retry_delay
      end
    end

    attr_reader :adaptor_config,
                :name, :url,
                :composer, :executor

    attr_accessor :http_method,
                  :retries, :retriable_errors, :retry_delay

    # @param url [string] the URL of the Operation instance (if different than the one in the Operation class)
    def initialize(url = self.class.base_url, adaptor_config: nil)
      self.url = url

      @adaptor_config = adaptor_config || Michigan.config.adaptor_config

      @composer = MiddlewareComposer.new
      @executor = Middleware::Execute.new

      @http_method = self.class.http_method
      @retries = self.class.retries || 0
      @retriable_errors = self.class.retriable_errors || []
      @retry_delay = self.class.retry_delay || 1

      yield self if block_given?

      add_default_middleware
      add_default_error_middleware
    end

    def url=(url)
      @url = url
      @name = "#{self.class.name} (#{self.class.http_method} #{url})"
    end

    # Append a namespace or resource to the URL
    #
    # @param param [string] the string to append
    # @return [Operation] A shallow copy of the Operation instance with the extended URL
    #
    # A copy of the operation is returned each time to allow chaining.
    #
    # Example:
    #   get_post = operation.url_param('namespace').url_param('posts').url_param(id)
    #   get_post.url
    #   # => https://thewebsite.com/namespace/posts/25
    def url_param(param)
      operation_copy = dup
      operation_copy.url = "#{@url}/#{param}"
      operation_copy
    end

    # Add a middleware to the middleware stack
    #
    # @param middleware [Object] the middleware to add to the stack
    def add_middleware(middleware)
      composer.add_middleware(middleware)
    end

    # Invoke the operation and yield to the inner block.
    #
    # @param args [any] the arguments used to build the headers and payload
    # @yieldparam method [symbol] the HTTP method defined in the Operation class
    # @yieldparam url [string] the URL defined in the Operation instance
    # @yieldparam request [Middleware::RequestBuilder::Request] the Request object
    # @return [any] the value returned by the block
    #
    # Invoking the Operation with +call+ yields to a block with the following parameters:
    # * +method+ - the HTTP method defined in the Operation class
    # * +url+ - the URL defined in the Operation instance constructor and any subsequent +url_param+ calls
    # * +request+ - a Request object
    #
    # Example:
    #   # Invoke a RESTful API using RestClient
    #   operation.call('John', 'Doe', '1972') do |method, url, request|
    #     h = request.headers
    #     p = request.payload
    #     RestClient::Request.execute(method: method, url: url, headers: h, payload: p)
    #   end
    def call(*args, **kwargs, &block)
      @executor.block = block

      context = {}
      composer.call(self, context, *args, **kwargs)
    end

    # Stubs

    def authenticate(*_args); end

    def headers(*_args); end

    def id(*_args); end

    def payload(*_args); end

    def validate(*_args); end

    private

    def add_default_middleware
      # Authenticate
      authenticate_method = method(:authenticate)
      authenticate = Middleware::Authenticate.new(authenticate_method)
      composer.add_middleware(authenticate)

      # BuildHeaders
      headers_method = method(:headers)
      build_headers = Middleware::BuildHeaders.new(headers_method)
      composer.add_middleware(build_headers)

      # BuildId
      id_method = method(:id)
      build_id = Middleware::BuildId.new(id_method)
      composer.add_middleware(build_id)

      # BuildPayload
      payload_method = method(:payload)
      build_payload = Middleware::BuildPayload.new(payload_method)
      composer.add_middleware(build_payload)

      # BuildRequest
      build_request = Middleware::BuildRequest.new
      composer.add_middleware(build_request)

      # LogRequest
      composer.add_middleware(Middleware::LogRequestStart.new)
      composer.add_middleware(Middleware::LogRequestComplete.new)

      # Execute
      composer.add_middleware(@executor)

      # Validate
      validate_method = method(:validate)
      validate = Middleware::Validate.new(validate_method)
      composer.add_middleware(validate)
    end

    def add_default_error_middleware
      composer.add_error_middleware(ErrorMiddleware::LogError.new)
      composer.add_error_middleware(ErrorMiddleware::LogRequestError.new)
      composer.add_error_middleware(ErrorMiddleware::LogValidationError.new)
      composer.add_error_middleware(ErrorMiddleware::PropagateValidationError.new)

      retries = self.retries
      if retries >= 1
        retriable_errors = self.retriable_errors
        retry_delay = self.retry_delay
        retry_middleware = ErrorMiddleware::Retry.new(retriable_errors: retriable_errors,
                                                      retries: retries,
                                                      delay: retry_delay)
        composer.add_error_middleware(retry_middleware)
      else
        composer.add_error_middleware(ErrorMiddleware::PropagateError.new)
        composer.add_error_middleware(ErrorMiddleware::PropagateRequestError.new)
      end
    end
  end
end
