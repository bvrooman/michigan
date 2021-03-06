# frozen_string_literal: true

RSpec.describe Michigan::Operation do
  describe '#url_param' do
    subject(:operation) { Support::GetPerson.new }

    it 'returns an operation with a url built from the base URL and the appended parameter' do
      new_operation = operation.url_param('id_90210')
      url = new_operation.url
      expect(url).to eq 'https://people.com/person/id_90210'
    end

    it 'can be chained to create a composite url' do
      new_operation = operation.url_param('namespace1').url_param('namespace2').url_param('resource')
      url = new_operation.url
      expect(url).to eq 'https://people.com/person/namespace1/namespace2/resource'
    end

    it 'returns a shallow copy of the original operation' do
      new_operation = operation.url_param('id_90210')
      expect(new_operation).not_to eq operation
      expect(operation.url).to eq 'https://people.com/person'
    end
  end

  describe '#call' do
    subject(:operation) do
      operation = Support::CreatePerson.new do |op|
        op.retries = 3
        op.retriable_errors = [Support::RetriableRequestError]
      end
      operation
    end

    let(:logger) { Logger.new($stdout) }
    let(:request_id) { '1-2-3' }

    before do
      Michigan.config.logger = logger
      allow(logger).to receive(:info).and_call_original
      allow(logger).to receive(:warn).and_call_original
      allow(logger).to receive(:error).and_call_original

      adaptor_config = Michigan::AdaptorConfig.new(status: 'code')
      Michigan.config.adaptor_config = adaptor_config

      stub_request(:any, operation.url).to_return(
        status: 200,
        body: 'CALL SUCCEEDED'
      )
    end

    it 'passes the correct method to its block' do
      operation.call('Abraham', 'Lincoln') do |method, _url, _request|
        expect(method).to eq :post
      end
    end

    it 'passes the correct url to its block' do
      operation.call('Abraham', 'Lincoln') do |_method, url, _request|
        expect(url).to eq 'https://people.com/person'
      end
    end

    it 'executes the call block' do
      operation.call('Abraham', 'Lincoln') do |method, url, request|
        Net::HTTP.send(method, URI(url), request.headers)
      end
      expect(a_request(:post, operation.url)).to have_been_made
    end

    it 'returns the return value of the call block' do
      response = operation.call('Abraham', 'Lincoln') do |method, url, request|
        Net::HTTP.send(method, URI(url), request.headers)
      end
      expect(response).to eq 'CALL SUCCEEDED'
    end

    it 'populates the request id' do
      r = nil
      operation.call('Abraham', 'Lincoln') do |method, url, request|
        r = request
        Net::HTTP.send(method, URI(url), request.headers)
      end
      expect(r.id).to eq request_id
    end

    it 'populates the request name' do
      r = nil
      operation.call('Abraham', 'Lincoln') do |method, url, request|
        r = request
        Net::HTTP.send(method, URI(url), request.headers)
      end
      expect(r.name).to eq "Request #{request_id} - Support::CreatePerson (post https://people.com/person)"
    end

    it 'populates the request headers' do
      operation.call('Abraham', 'Lincoln') do |_method, _url, request|
        expected_headers = { request_id: request_id }
        headers = request.headers
        expect(headers).to eq expected_headers
      end
    end

    it 'populates the request payload' do
      operation.call('Abraham', 'Lincoln') do |_method, _url, request|
        expected_payload = { first_name: 'Abraham', last_name: 'Lincoln' }
        payload = request.payload
        expect(payload).to eq expected_payload
      end
    end

    it 'populates the request payload when using keyword arguments' do
      operation = Support::UpdatePerson.new
      operation.call(first_name: 'Abe') do |_method, _url, request|
        expected_payload = { first_name: 'Abe' }
        payload = request.payload
        expect(payload).to eq expected_payload
      end
    end

    it 'populates the request response body' do
      r = nil
      operation.call('Abraham', 'Lincoln') do |method, url, request|
        r = request
        Net::HTTP.send(method, URI(url), request.headers)
      end
      expect(r.response.body).to eq 'CALL SUCCEEDED'
    end

    it 'populates request response error and error message when an error occurs' do
      r = nil
      begin
        operation.call('Abraham', 'Lincoln') do |_method, _url, request|
          r = request
          raise Support::RequestError, 'An internal sever error has occurred.'
        end
      rescue StandardError
        expect(r.response.error.class).to eq Support::RequestError
        expect(r.response.error_message).to eq 'An internal sever error has occurred.'
      end
    end

    it 'populates the request response HTTP code when an HTTP error occurs' do
      r = nil
      begin
        operation.call('Abraham', 'Lincoln') do |_method, _url, request|
          r = request
          raise Support::RequestError, 'An internal sever error has occurred.'
        end
      rescue StandardError
        expect(r.response.http_code).to eq 500
      end
    end

    it 'raises the validation error thrown by the validate method' do
      expect do
        operation.call('Abraham', nil)
      end.to raise_error(Support::CreatePerson::ValidationError)
    end

    it 'executes middleware in the order specified by their dependencies' do
      consumer_class = Class.new(Object) do
        def self.name
          'Consumer'
        end

        def call(_operation, context, *_args)
          context[:resource] *= 2
        end

        def inputs
          # This middleware consumes the dependency
          [:resource]
        end
      end

      producer_class = Class.new(Object) do
        def self.name
          'Producer'
        end

        def call(_operation, context, *_args)
          context[:resource] = 2
        end

        def outputs
          # This middleware produces the dependency
          [:resource]
        end
      end

      consumer = consumer_class.new
      producer = producer_class.new
      allow(consumer).to receive(:call).and_call_original
      allow(producer).to receive(:call).and_call_original
      operation.add_middleware(consumer)
      operation.add_middleware(producer)
      resource = operation.call('Abraham', 'Lincoln')
      expect(producer).to have_received(:call).ordered # consumer depends on producer; execute producer first
      expect(consumer).to have_received(:call).ordered # consumer will execute after producer
      expect(resource).to eq 4
    end

    it 'raises the expected error on non-retriable errors' do
      expect do
        operation.call('Abraham', 'Lincoln') do |method, url, request|
          Net::HTTP.send(method, URI(url), request.headers)
          raise Support::RequestError, 'An internal sever error has occurred.'
        end
      end.to raise_error Support::RequestError
    end

    it 'retries on retriable errors' do
      begin
        operation.call('Abraham', 'Lincoln') do |method, url, request|
          Net::HTTP.send(method, URI(url), request.headers)
          raise Support::RetriableRequestError, 'An internal sever error has occurred.'
        end
      rescue StandardError
        # Ignore
      end

      expect(a_request(:post, operation.url)).to have_been_made.times(1 + 3) # 1 for original, 3 for retries
    end

    it 'raises the expected error on retriable errors' do
      expect do
        operation.call('Abraham', 'Lincoln') do |method, url, request|
          Net::HTTP.send(method, URI(url), request.headers)
          raise Support::RetriableRequestError, 'An internal sever error has occurred.'
        end
      end.to raise_error Support::RetriableRequestError
    end

    it 'logs that the request is starting' do
      operation.call('Abraham', 'Lincoln') do |method, url, request|
        Net::HTTP.send(method, URI(url), request.headers)
      end
      expect(logger).to have_received(:info).with(/starting/)
    end

    it 'logs that the request has completed' do
      operation.call('Abraham', 'Lincoln') do |method, url, request|
        Net::HTTP.send(method, URI(url), request.headers)
      end
      expect(logger).to have_received(:info).with(/completed/)
    end

    it 'logs that the request failed when a request failure occurs' do
      begin
        operation.call('Abraham', 'Lincoln') do |method, url, request|
          Net::HTTP.send(method, URI(url), request.headers)
          raise Support::RequestError, 'An internal sever error has occurred.'
        end
      rescue StandardError
        # Ignore
      end
      expect(logger).to have_received(:error).with(/failed/)
    end

    it 'logs that validation failed when a request fails validation' do
      begin
        operation.call('Abraham', nil) do |method, url, request|
          Net::HTTP.send(method, URI(url), request.headers)
        end
      rescue StandardError
        # Ignore
      end
      expect(logger).to have_received(:error).with(/validation error/)
    end

    it 'logs that an error occurred on an internal error' do
      middleware_klass = Class.new(Object) do
        def inputs
          [:request]
        end

        def outputs
          [:modified_request]
        end

        def call(_operation, _context, *_args)
          raise StandardError, 'Something went wrong!'
        end
      end

      middleware = middleware_klass.new
      operation.add_middleware(middleware)
      operation.executor.inputs << :modified_request

      begin
        operation.call('Abraham', 'Lincoln') do |method, url, request|
          Net::HTTP.send(method, URI(url), request.headers)
        end
      rescue StandardError
        # Ignore
      end
      expect(logger).to have_received(:error).with(/internal error/)
    end
  end

  describe 'subclasses' do
    let(:base_class) do
      klass = Class.new(described_class)
      klass.http_method = :post
      klass.base_url = 'https://www.website.com'
      klass.retries = 3
      klass.retriable_errors = [Support::RetriableRequestError]
      klass.retry_delay = 1
      klass
    end

    let(:child_class) do
      klass = Class.new(base_class)
      klass.base_url = "#{base_class.base_url}/namespace"
      klass
    end

    let(:grandchild_class) { Class.new(child_class) }

    it 'inherit superclass config' do
      instance = child_class.new
      expect(instance.http_method).to eq :post
      expect(instance.url).to eq 'https://www.website.com/namespace'
      expect(instance.retries).to eq 3
      expect(instance.retriable_errors).to eq [Support::RetriableRequestError]
      expect(instance.retry_delay).to eq 1

      instance = grandchild_class.new
      expect(instance.http_method).to eq :post
      expect(instance.url).to eq 'https://www.website.com/namespace'
      expect(instance.retries).to eq 3
      expect(instance.retriable_errors).to eq [Support::RetriableRequestError]
      expect(instance.retry_delay).to eq 1
    end
  end
end
