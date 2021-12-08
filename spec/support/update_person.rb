# frozen_string_literal: true

module Support
  class UpdatePerson < Michigan::Operation
    self.http_method = :post
    self.retriable_errors = []
    self.retries = 3
    self.retry_delay = 0

    class ValidationError < StandardError; end

    def initialize
      super('https://people.com/person')
    end

    def id(*_args)
      '1-2-3'
    end

    def headers(context, *_args)
      {
        request_id: context[:id]
      }
    end

    def payload(_context, first_name: nil, last_name: nil)
      {
        first_name: first_name,
        last_name: last_name
      }.compact
    end
  end
end
