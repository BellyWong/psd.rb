class PSD
  class Slice
    attr_reader :id, :group_id, :origin, :associated_layer_id, :name, :type,
                :bounds, :url, :target, :message, :alt, :cell_text_is_html,
                :cell_text, :horizontal_alignment, :vertical_alignment,
                :color

    def initialize(psd, data)
      @psd = psd
      data.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    [:left, :top, :right, :bottom].each do |dir|
      define_method(dir) { @bounds[dir] }
    end

    def width
      right - left
    end

    def height
      bottom - top
    end

    def associated_layer
      @psd.tree.find_by_id(associated_layer_id)
    end
  end
end
