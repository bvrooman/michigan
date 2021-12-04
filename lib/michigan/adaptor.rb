# frozen_string_literal: true

module Michigan
  class AdaptorConfig
    attr_reader :body_method_name, :status_method_name

    def initialize(body: 'body', status: 'status')
      @body_method_name = body
      @status_method_name = status
    end
  end

  class Adaptor
    attr_reader :response, :config

    def initialize(response, config:)
      @response = response
      @config = config
    end

    def body
      if response.respond_to?(config.body_method_name)
        response.send(config.body_method_name)
      else
        response
      end
    end

    def status
      response.send(config.status_method_name) if response.respond_to?(config.status_method_name)
    end
  end
end
