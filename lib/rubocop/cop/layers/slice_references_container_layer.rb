# frozen_string_literal: true

module RuboCop
  module Cop
    module Layers
      # Slices (engines, api engines, components) never statically name the
      # container's layer families: use cases and query objects live in the
      # container and are reached through injected registries
      # (`Engine.configuration.use_cases[:key]` / `.queries[:key]`), not by
      # constant reference. Naming one breaks the slice's standalone suite.
      #
      # Detects `UseCases::` and `Queries::` references inside files under the
      # configured slice paths. Model constants are not statically detectable —
      # `layers:doctor` and review cover those.
      class SliceReferencesContainerLayer < Base
        MSG = 'A slice never names the container layer %<family>s::* — resolve through ' \
              'the injected registry (Engine.configuration.use_cases / .queries).'

        CONTAINER_FAMILIES = [:UseCases, :Queries].freeze

        DEFAULT_SLICE_PATHS = [
          '/engines/',
          '/apis/',
          '/components/',
        ].freeze

        def on_const(node)
          family = container_family(node)
          return unless family
          return if definition_name?(node)
          return unless slice_file?

          add_offense(node, message: format(MSG, family: family))
        end


        private

        def container_family(node)
          namespace = node.children.first
          return unless namespace.nil? || namespace.cbase_type?

          name = node.children[1]
          name if CONTAINER_FAMILIES.include?(name)
        end

        def definition_name?(node)
          outermost = node
          outermost = outermost.parent while outermost.parent&.const_type?
          parent = outermost.parent
          return false unless parent&.module_type? || parent&.class_type?

          parent.identifier.equal?(outermost)
        end

        def slice_file?
          path = processed_source.file_path.to_s
          slice_paths.any? { |slice| path.include?(slice) }
        end

        def slice_paths
          cop_config.fetch('SlicePaths', DEFAULT_SLICE_PATHS)
        end
      end
    end
  end
end
