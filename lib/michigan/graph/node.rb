# frozen_string_literal: true

require_relative 'dependency_graph'

module Michigan
  module Graph
    class Node
      class UndeclaredDependencyError < StandardError
        def initialize(producer, dependency)
          message = "Producer #{producer} requires the resource \"#{dependency}\" as a dependency. "\
                    "However, the resource \"#{dependency}\" was not declared by any previous producer as an output! "\
                    'Did you forget to add the producer?'
          super(message)
        end
      end

      attr_reader :producer, :dependencies

      def initialize(producer, dependency_producer_map)
        @producer = producer
        @dependency_producer_map = dependency_producer_map
        @dependencies = []
        @dependency_graph = DependencyGraph.new(self)

        declare_outputs
      end

      def prepare
        declare_inputs
      end

      def ordered_dependencies
        dependency_graph.resolve_dependencies
      end

      def call(*args)
        producer.call(*args)
      end

      private

      attr_reader :dependency_producer_map, :dependency_graph

      def declare_inputs
        return unless producer.respond_to?(:inputs)

        inputs = producer.send(:inputs)
        inputs.each do |input|
          declare_input(input)
        end
      end

      def declare_outputs
        return unless producer.respond_to?(:outputs)

        outputs = producer.send(:outputs)
        outputs.each do |output|
          declare_output(output)
        end
      end

      def declare_output(output)
        dependency_producer_map[output] = self
      end

      def declare_input(input)
        raise UndeclaredDependencyError.new(producer.class.name, input) unless dependency_producer_map.key?(input)

        resource_producer = dependency_producer_map[input]
        add_dependency(resource_producer)
      end

      def add_dependency(dependency)
        dependencies << dependency
      end
    end
  end
end
