require 'lib/psd/layer_info'

class PSD
  class ReferencePoint < LayerInfo
    def self.should_parse?(key)
      key == 'fxrp'
    end

    attr_reader :x, :y

    def parse
      @x = @file.read_double
      @y = @file.read_double

      return self
    end
  end
end