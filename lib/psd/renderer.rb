require_relative 'renderer/canvas_management'

class PSD
  class Renderer
    include CanvasManagement

    def initialize(node)
      @root_node = node

      # Our canvas always starts as the full document size because
      # all measurements are relative to this size. We can later crop
      # the image if needed.
      @width = @root_node.document_dimensions[0].to_i
      @height = @root_node.document_dimensions[1].to_i

      @canvas_stack = []
      @node_stack = [@root_node]

      @rendered = false
    end

    def render!
      # Create our base canvas
      create_group_canvas(active_node)

      # Begin the rendering process
      execute_pipeline

      @rendered = true
    end

    def execute_pipeline
      children.each do |child|
        # We skip over hidden nodes. Maybe something configurable in the future?
        next unless child.visible?

        if child.group?
          push_node(child)

          if group_is_passthru?(child)
            execute_pipeline
          else
            create_group_canvas(child, child.width, child.height)
            execute_pipeline
            child_canvas = pop_canvas

            child_canvas.paint_to active_canvas
          end

          pop_node and next
        end

        canvas = Canvas.new(child, child.width, child.height)
        canvas.paint_to active_canvas
      end
    end

    def to_png
      render! unless @rendered
      active_canvas
    end

    private

    def children
      if active_node.layer?
        [active_node]
      else
        active_node.children
      end
    end

    def push_node(node)
      @node_stack << node
    end

    def pop_node
      @node_stack.pop
    end

    def active_node
      @node_stack.last
    end

    def group_is_passthru?(node)
      node.blending_mode == 'passthru'
    end
  end
end