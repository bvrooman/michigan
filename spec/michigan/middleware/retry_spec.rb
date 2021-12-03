# frozen_string_literal: true

class MiddlewareA
  def inputs
    []
  end

  def outputs
    [:output_a]
  end

  def call(_operation, _context); end
end

class MiddlewareB
  def inputs
    [:output_a]
  end

  def outputs
    [:output_b]
  end

  def call(_operation, _context); end
end

class MiddlewareC
  def inputs
    [:output_b]
  end

  def outputs
    [:response]
  end

  def call(_operation, _context); end
end

class MiddlewareD
  def call(_operation, _context); end
end

RSpec.describe Michigan::ErrorMiddleware::Retry, type: :middleware do
  subject(:retry_middleware) do
    described_class.new(
      retriable_errors: [Support::RetriableRequestError],
      retries: 3,
      delay: 0
    )
  end

  let(:context) do
    {
      retries: 0
    }
  end
  let(:logger) { Logger.new($stdout) }
  let(:operation) { Support::CreatePerson.new }
  let(:middleware_a) { operation.composer.create_dependency(MiddlewareA.new) }
  let(:middleware_b) { operation.composer.create_dependency(MiddlewareB.new) }
  let(:middleware_c) { operation.composer.create_dependency(MiddlewareC.new) }
  let(:middleware_d) { operation.composer.create_dependency(MiddlewareD.new) }

  before do
    Michigan.config.logger = logger
    allow(logger).to receive(:info).and_call_original
    allow(logger).to receive(:warn).and_call_original

    [middleware_a, middleware_b, middleware_c, middleware_d].each(&:prepare)
  end

  describe '#call' do
    context 'without an error' do
      it 'does not augment the number of retries' do
        expect do
          retry_middleware.call(operation, context)
        end.to change { context[:retries] }.by 0
      end

      it 'does not log anything if no retries occurred' do
        retry_middleware.call(operation, context)
        expect(logger).not_to have_received(:info)
      end

      it 'logs that the request succeeded after n retries if any retries occurred' do
        context[:retries] = 2
        retry_middleware.call(operation, context)
        expect(logger).to have_received(:info).with('Request succeeded after 2 retries.')
      end
    end

    context 'with a retriable error' do
      before do
        context[:error] = Support::RetriableRequestError.new
        context[:failed_middleware] = middleware_c
      end

      it 'augments the number of retries' do
        expect do
          retry_middleware.call(operation, context)
        end.to change { context[:retries] }.by 1
      end

      it 'prepends the failed middleware dependency chain to the call queue' do
        operation.composer.call_queue.enqueue_middleware(middleware_d)
        retry_middleware.call(operation, context)
        expect(operation.composer.call_queue.queue).to eq [middleware_a, middleware_b, middleware_c, middleware_d]
      end

      it 'enqueues PropagateError and PropagateRequestError middleware to the error queue if all retries have been exhausted' do
        context[:retries] = 3
        retry_middleware.call(operation, context)
        producers = operation.composer.error_queue.queue.map(&:producer)
        expect(producers).to include(an_instance_of(Michigan::ErrorMiddleware::PropagateError))
        expect(producers).to include(an_instance_of(Michigan::ErrorMiddleware::PropagateRequestError))
      end

      it 'logs that the request failed after n retries if all retries have been exhausted' do
        context[:retries] = 3
        retry_middleware.call(operation, context)
        expect(logger).to have_received(:warn).with('Request failed after 3 retries.')
      end
    end

    context 'with a non-retriable error' do
      before do
        context[:error] = Support::NonRetriableRequestError.new
        context[:failed_middleware] = middleware_c
      end

      it 'does not augment the number of retries' do
        expect do
          retry_middleware.call(operation, context)
        end.to change { context[:retries] }.by 0
      end

      it 'enqueues  PropagateError and PropagateRequestError middleware to the error queue' do
        retry_middleware.call(operation, context)
        producers = operation.composer.error_queue.queue.map(&:producer)
        expect(producers).to include(an_instance_of(Michigan::ErrorMiddleware::PropagateError))
        expect(producers).to include(an_instance_of(Michigan::ErrorMiddleware::PropagateRequestError))
      end

      it 'does not log anything if no retries occurred' do
        retry_middleware.call(operation, context)
        expect(logger).not_to have_received(:warn)
      end

      it 'logs that the request failed after n retries if any retries occurred' do
        context[:retries] = 2
        retry_middleware.call(operation, context)
        expect(logger).to have_received(:warn).with('Request failed after 2 retries.')
      end
    end
  end
end
