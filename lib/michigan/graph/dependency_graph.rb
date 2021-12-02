# frozen_string_literal: true

module Michigan
  module Graph
    class DependencyGraph
      attr_reader :root_node

      def initialize(root_node)
        @root_node = root_node
      end

      def resolve_dependencies
        resolved = []
        DependencyGraph.resolve(root_node, resolved)
        resolved
      end

      def self.resolve(root, resolved)
        dependencies = root.dependencies
        dependencies.each do |dependency|
          resolve(dependency, resolved) unless resolved.include?(dependency)
        end
        resolved << root
      end
    end
  end
end
