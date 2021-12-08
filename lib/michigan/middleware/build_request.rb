# frozen_string_literal: true

module Michigan
  module Middleware
    class BuildRequest
      class Response
        attr_accessor :body,
                      :error,
                      :error_message,
                      :http_code
      end

      class Request
        def initialize
          @response = Response.new
        end

        attr_reader   :response
        attr_accessor :authentication,
                      :headers,
                      :id,
                      :method,
                      :name,
                      :payload,
                      :url

        def to_hash
          {
            method: method,
            url: url,
            headers: headers,
            payload: payload
          }
        end
      end

      def inputs
        @inputs ||= %i[authentication headers id payload]
      end

      def outputs
        [:request]
      end

      def call(operation, context, *_args, **_kwargs)
        # Read the inputs from the context
        authentication =  context[:authentication]
        headers =         context[:headers]
        id =              context[:id]
        payload =         context[:payload]

        name = "Request #{id} - #{operation.name}"
        request = build_request(
          authentication: authentication,
          headers: headers,
          id: id,
          method: operation.http_method,
          name: name,
          payload: payload,
          url: operation.url
        )

        context[:request] = request
        context[:requests] ||= []
        context[:requests] << request

        request
      end

      private

      def build_request(name:, url:, method:, authentication:, headers:, id:, payload:)
        request = Request.new
        request.id =              id
        request.url =             url
        request.method =          method
        request.name =            name
        request.authentication =  authentication
        request.headers =         headers
        request.payload =         payload
        request
      end
    end
  end
end
