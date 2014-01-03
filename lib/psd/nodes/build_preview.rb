 class PSD
  class Node
    module BuildPreview
      include PSD::Image::Export::PNG

      alias :orig_to_png :to_png
      def to_png
        PSD::Renderer.new(self).to_png
      end

      def build_png(png=nil)
        png ||= create_canvas

        children.reverse.each do |c|
          next unless c.visible?

          if c.group?
            if c.blending_mode == 'passthru'
              c.build_png(png)
            else
              compose! c, png, c.build_png, 0, 0
            end
          else
            compose!(
              c, 
              png, 
              c.image.to_png_with_mask(layer_styles: false),
              PSD::Util.clamp(c.left.to_i, 0, png.width),
              PSD::Util.clamp(c.top.to_i, 0, png.height)
            )
          end
        end

        group? && image.has_mask? ? apply_group_mask(png) : png
      end

      private

      def create_canvas
        width, height = document_dimensions
        ChunkyPNG::Canvas.new(width.to_i, height.to_i, ChunkyPNG::Color::TRANSPARENT)
      end

      # Modified from ChunkyPNG::Canvas#compose! in order to support various blend modes.
      def compose!(layer, base, other, offset_x, offset_y)
        blending_mode = layer.blending_mode.gsub(/ /, '_')
        PSD.logger.warn("Blend mode #{blending_mode} is not implemented") unless Compose.respond_to?(blending_mode)
        PSD.logger.debug("Blending #{layer.name} with #{blending_mode} blend mode")

        other = ClippingMask.new(layer, other).apply
        LayerStyles.new(layer, base, other).apply!

        blend_pixels!(blending_mode, layer, base, other, offset_x, offset_y)
      end

      def blend_pixels!(blending_mode, layer, base, other, offset_x, offset_y)
        other.height.times do |y|
          other.width.times do |x|
            base_x = x + offset_x
            base_y = y + offset_y

            next if base_x < 0 || base_y < 0 || base_x >= base.width || base_y >= base.height

            color = Compose.send(
              blending_mode,
              other[x, y],
              base[base_x, base_y],
              opacity: layer.opacity,
              fill_opacity: layer.fill_opacity
            )

            base[base_x, base_y] = color
          end
        end
      end

      def apply_group_mask(png)
        service = MaskService.new(layer)
        service.pixel_data = png.pixels
        service.layer_width = png.width
        service.layer_height = png.height
        service.apply
      end
    end
  end
end
