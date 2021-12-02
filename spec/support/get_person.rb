# frozen_string_literal: true

module Support
  class GetPerson < Michigan::Operation
    self.http_method = :get
    self.retriable_errors = []
    self.retries = 3
    self.retry_delay = 0

    def initialize
      super('https://people.com/person')
    end

    def headers(context, *_args)
      {
        request_id: context[:id]
      }
    end
  end
end
