module Doocr
  class KeyBinding
    class_getter empty : KeyBinding = new()

    getter keys : Array(DoomKey)
    getter mouse_buttons : Array(DoomMouseButton)

    private def initialize
      @keys = [] of DoomKey
      @mouse_buttons = [] of DoomMouseButton
    end

    def initialize(@keys : Array(DoomKey))
      @mouse_buttons = [] of DoomMouseButton
    end

    def initialize(@keys : Array(DoomKey), @mouse_buttons : Array(DoomMouseButton))
    end

    def to_s
      key_values = @keys.select { |key| DoomKeyEx.to_s(key) }
      mouse_values = @mouse_buttons.select { |button| DoomMouseButtonEx.to_s(button) }
      values = key_values + mouse_values
      if values.size > 0
        s = ""
        values.each do |v|
          s = s + v + ", "
        end
        s = s.rchop

        return s
      else
        return "none"
      end
    end

    def self.parse(value : String)
      return @empty if value == "none"

      keys = [] of DoomKey
      mouse_buttons = [] of DoomMouseButton

      split = value.split(',').select { |x| x.strip }
      split.each do |s|
        key = DoomKeyEx.parse(s)
        if key != DoomKey::Unknown
          keys << key
          next
        end

        mouse_button = DoomMouseButton.parse(s)
        if mouse_button != DoomMouseButton::Unknown
          mouse_buttons << mouse_button
        end
      end

      return KeyBinding.new(keys, mouse_buttons)
    end
  end
end
