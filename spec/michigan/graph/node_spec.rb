# frozen_string_literal: true

require 'michigan/graph/node'

class RequestMaker
  def outputs
    [:request]
  end
end

class RequestToken
  def outputs
    [:token]
  end
end

class RequestSigner
  def inputs
    %i[request token]
  end

  def outputs
    [:signed_request]
  end
end

class RequestSender
  def inputs
    [:signed_request]
  end

  def outputs
    [:response]
  end
end

RSpec.describe Michigan::Graph::Node do
  describe 'prepare' do
    it "raises an UndeclaredResourceError if the wrapped producer's dependency was not declared as an output" do
      request_maker = RequestMaker.new
      request_signer = RequestSigner.new

      resource_producer_map = {}
      _wrapper_maker = Michigan::Graph::Node.new(request_maker, resource_producer_map)
      wrapper_signer = Michigan::Graph::Node.new(request_signer, resource_producer_map)
      # Do not create a producer for the resource `:token`

      expect do
        wrapper_signer.prepare
      end.to raise_error Michigan::Graph::Node::UndeclaredDependencyError
    end
  end

  describe 'ordered_dependencies' do
    it 'returns the list of ordered dependencies for the wrapped producer' do
      request_maker = RequestMaker.new
      request_token = RequestToken.new
      request_signer = RequestSigner.new
      request_sender = RequestSender.new

      dependency_producer_map = {}
      wrapper_maker = Michigan::Graph::Node.new(request_maker, dependency_producer_map)
      wrapper_sender = Michigan::Graph::Node.new(request_sender, dependency_producer_map)
      wrapper_signer = Michigan::Graph::Node.new(request_signer, dependency_producer_map)
      wrapper_token = Michigan::Graph::Node.new(request_token, dependency_producer_map)

      # Prepare once all wrappers are created
      wrapper_maker.prepare
      wrapper_sender.prepare
      wrapper_signer.prepare
      wrapper_token.prepare

      resolved_dependencies = wrapper_sender.ordered_dependencies.map(&:producer)
      expect(resolved_dependencies).to eq [request_maker, request_token, request_signer, request_sender]
    end

    it 'returns an a list containing only wrapped producer if the producer has no dependencies' do
      request_maker = RequestMaker.new

      resource_producer_map = {}
      wrapper_maker = Michigan::Graph::Node.new(request_maker, resource_producer_map)

      # Prepare once all wrappers are created
      wrapper_maker.prepare

      resolved_dependencies = wrapper_maker.ordered_dependencies.map(&:producer)
      expect(resolved_dependencies).to eq [request_maker]
    end
  end
end
