# frozen_string_literal: true

module Support
  class CreatePerson < Michigan::Operation
    self.http_method = :post
    self.retriable_errors = []
    self.retries = 3
    self.retry_delay = 0

    class ValidationError < StandardError; end

    def initialize
      super('https://people.com/person')
    end

    def validate(first_name, last_name)
      raise ValidationError, 'First name must be provided!' if first_name.nil?
      raise ValidationError, 'Last name must be provided!' if last_name.nil?
    end

    def headers(context, *_args)
      {
        request_id: context[:id]
      }
    end

    def payload(_context, first_name, last_name)
      {
        first_name: first_name,
        last_name: last_name
      }
    end
  end
end
