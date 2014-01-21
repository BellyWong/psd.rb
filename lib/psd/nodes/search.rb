class PSD
  class Node
    module Search
      # Searches the tree structure for a node at the given path. The path is
      # defined by the layer/folder names. Because the PSD format does not
      # require unique layer/folder names, we always return an array of all
      # found nodes.
      def children_at_path(path, opts={})
        path = path.split('/').delete_if { |p| p == "" } unless path.is_a?(Array)

        query = path.shift
        matches = children.select do |c|
          if opts[:case_sensitive]
            c.name == query
          else
            c.name.downcase == query.downcase
          end
        end

        if path.length == 0
          return matches
        else
          return matches.map { |m| m.children_at_path(path, opts) }.flatten
        end
      end
      alias :children_with_path :children_at_path

      # Given a layer comp ID, name, or :last for last document state, create a new
      # tree with layer/group visibility altered based on the layer comp.
      def filter_by_comp(id)
        if id.is_a?(String)
          comp = psd.layer_comps.select { |c| c[:name] == id }.first
          raise "Layer comp not found" if comp.nil?

          id = comp[:id]
        elsif id == :last
          id = 0
        end

        root = PSD::Node::Root.new(psd)
        filter_for_comp!(id, root)

        return root
      end

      private

      def filter_for_comp!(id, node)
        # Force layers to be visible if they are enabled for the comp
        node.children.each do |c|
          enabled = false

          c
            .metadata
            .data[:layer_comp]['layerSettings'].each do |l|
              enabled = l['enab'] if l.has_key?('enab')
              break if l['compList'].include?(id)
            end

          c.force_visible = enabled
          filter_for_comp!(id, c) if c.group?
        end
      end
    end
  end
end