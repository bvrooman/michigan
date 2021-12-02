module Support
  class RequestError < StandardError
    attr_reader :status

    def initialize(*args)
      super
      @status = 500
    end
  end

  class RetriableRequestError < RequestError; end

  class NonRetriableRequestError < RequestError; end
end
