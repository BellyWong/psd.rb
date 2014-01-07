class PSD
  class Renderer
    class Blender
      attr_reader :fg, :bg

      # Takes a foreground Canvas and a background Canvas
      def initialize(fg, bg)
        @fg = fg
        @bg = bg
      end

      # Composes the foreground Canvas onto the background Canvas using the
      # blending mode specified by the foreground.
      def compose!
        PSD.logger.debug "Composing #{fg.node.name} onto #{bg.node.name || ":root:"} with #{fg.node.blending_mode} blending"

        offset_x = PSD::Util.clamp(fg.left - bg.left, 0, bg.width)
        offset_y = PSD::Util.clamp(fg.top - bg.top, 0, bg.height) 

        fg.height.times do |y|
          fg.width.times do |x|
            base_x = x + offset_x
            base_y = y + offset_y

            next if base_x < 0 || base_y < 0 || base_x >= bg.width || base_y >= bg.height

            color = Compose.send(
              fg.node.blending_mode,
              fg.canvas[x, y],
              bg.canvas[base_x, base_y],
              opacity: fg.node.opacity,
              fill_opacity: fg.node.fill_opacity
            )

            bg.canvas[base_x, base_y] = color
          end
        end
      end
    end
  end
end