class PSD
  module ImageMode
    # Combines the channel data from the image into RGB pixel values
    module RGB
      private

      def set_rgb_channels
        @channels_info = [
          {id: 0},
          {id: 1},
          {id: 2}
        ]

        @channels_info << {id: -1} if channels == 4
      end

      def combine_rgb_channel
        PSD.logger.debug "Beginning RGB processing"

        rgb_channels = @channels_info.map { |ch| ch[:id] }.reject { |ch| ch < -1 }

        (0...@num_pixels).step(pixel_step) do |i|
          r = g = b = 0
          a = 255

          rgb_channels.each_with_index do |chan, index|
            val = @channel_data[i + (@channel_length * index)]

            case chan
            when -1 then  a = val
            when 0 then   r = val
            when 1 then   g = val
            when 2 then   b = val
            end
          end

          @pixel_data.push ChunkyPNG::Color.rgba(r, g, b, a)
        end
      end
    end
  end
end
