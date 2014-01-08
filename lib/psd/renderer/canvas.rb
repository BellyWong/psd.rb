class PSD
  class Renderer
    class Canvas
      attr_accessor :canvas
      attr_reader :node, :width, :height, :left, :right, :top, :bottom

      def initialize(node, width = nil, height = nil, color = ChunkyPNG::Color::TRANSPARENT)
        @node = node
        @pixel_data = @node.root? ? [] : @node.image.pixel_data
        
        @width = (width || @node.width).to_i
        @height = (height || @node.height).to_i
        @left = @node.left.to_i
        @right = @node.right.to_i
        @top = @node.top.to_i
        @bottom = @node.bottom.to_i

        @canvas = ChunkyPNG::Canvas.new(@width, @height, color)

        initialize_canvas
      end

      def paint_to(base)
        PSD.logger.debug "Painting #{node.name} to #{base.node.debug_name}"

        apply_mask
        apply_clipping_mask
        apply_layer_styles
        apply_layer_opacity
        compose_pixels(base)
      end

      def [](x, y); @canvas[x, y]; end
      def []=(x, y, value); @canvas[x, y] = value; end

      def method_missing(method, *args, &block)
        @canvas.send(method, *args, &block)
      end

      private

      def initialize_canvas
        return if node.root? || node.group?

        PSD.logger.debug "Initializing canvas for #{node.debug_name}"

        i = 0
        height.times do |y|
          width.times do |x|
            @canvas[x, y] = @pixel_data[i]
            i += 1
          end
        end

        # This can now be referenced by @canvas.pixels
        @pixel_data = nil
      end

      def apply_mask
        return unless @node.image.has_mask?

        PSD.logger.debug "Applying layer mask to #{node.name}"
        Mask.new(self).apply!
      end

      def apply_clipping_mask
        return unless @node.clipped?
        ClippingMask.new(self).apply!
      end

      def apply_layer_styles
        PSD.logger.debug "Applying layer styles to #{node.name}"
        LayerStyles.new(self).apply!
      end

      def apply_layer_opacity
        PSD.logger.debug "Adjusting opacity for #{node.name}"
        return if @node.root?

        opacity = @node.opacity.to_f
        @node.ancestors.each do |parent|
          break unless parent.passthru_blending?
          opacity = (opacity * parent.opacity.to_f) / 255.0
        end

        PSD.logger.debug "Inherited opacity for #{@node.debug_name} is #{opacity}"
        return if opacity == 255.0

        @canvas.pixels.map do |pixel|
          (pixel & 0xffffff00) | (ChunkyPNG::Color.a(pixel) * opacity.to_i / 255)
        end
      end

      def compose_pixels(base)
        Blender.new(self, base).compose!
      end
    end
  end
end