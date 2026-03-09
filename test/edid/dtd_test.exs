defmodule Edid.DTDTest do
  use ExUnit.Case, async: true
  doctest Edid.DTD

  alias Edid.DTD
  alias Edid.Modeline

  describe inspect(&DTD.generate/1) do
    test "should generate DTD for a parsed modeline string" do
      # Use a modeline with clock under 65.535 MHz (65535 kHz) for proper 16-bit storage
      modeline_str = "51.00 800 840 856 896 600 601 604 624 -HSync +Vsync"
      modeline = Modeline.parse(modeline_str)

      dtd = DTD.generate(modeline)

      assert byte_size(dtd) == 18
    end

    test "should generate correct DTD bytes for known modeline" do
      modeline_str = "44.194 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync"
      modeline = Modeline.parse(modeline_str)

      dtd = DTD.generate(modeline)

      # Check clock bytes (stored in 10kHz units)
      # 44194 kHz / 10 = 4419 (10kHz units) = 0x114B little-endian
      <<clock_low::8, clock_high::8, _::binary>> = dtd
      # 0x4B = 75
      assert clock_low == rem(div(44_194, 10), 256)
      # 0x11 = 17
      assert clock_high == rem(div(div(44_194, 10), 256), 256)

      # For digital separate sync (bits 4-3 = 11), sync polarities are in bits 2-1
      # h_sync=0, v_sync=1 should give bit2=1, bit1=0 = 0b00000100 = 4
      <<_::136, flags::8>> = dtd
      assert Bitwise.band(Bitwise.bsr(flags, 1), 0x03) == 2
    end

    test "should handle positive sync polarities" do
      modeline_str = "44.194 3000 3032 3064 3600 2000 2003 2008 2046 +HSync +Vsync"
      modeline = Modeline.parse(modeline_str)

      dtd = DTD.generate(modeline)

      # h_sync=1, v_sync=1 should give bit2=1, bit1=1 = 0b00000110 = 6
      <<_::136, flags::8>> = dtd
      assert Bitwise.band(Bitwise.bsr(flags, 1), 0x03) == 3
    end

    test "should handle negative sync polarities" do
      modeline_str = "44.194 3000 3032 3064 3600 2000 2003 2008 2046 -HSync -Vsync"
      modeline = Modeline.parse(modeline_str)

      dtd = DTD.generate(modeline)

      # h_sync=0, v_sync=0 should give bit2=0, bit1=0 = 0b00000000 = 0
      <<_::136, flags::8>> = dtd
      assert Bitwise.band(Bitwise.bsr(flags, 1), 0x03) == 0
    end

    test "should handle mixed polarities" do
      modeline_str = "44.194 3000 3032 3064 3600 2000 2003 2008 2046 +HSync -Vsync"
      modeline = Modeline.parse(modeline_str)

      dtd = DTD.generate(modeline)

      # h_sync=1, v_sync=0 should give bit2=0, bit1=1 = 0b00000010 = 2
      <<_::136, flags::8>> = dtd
      assert Bitwise.band(Bitwise.bsr(flags, 1), 0x03) == 1
    end

    test "should generate interlaced DTD" do
      modeline_str = "44.194 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync Interlace"
      modeline = Modeline.parse(modeline_str)

      dtd = DTD.generate(modeline)

      # Bit 7 should be 1 for interlaced (bit 7 = 0x80)
      <<_::136, flags::8>> = dtd
      assert Bitwise.band(flags, 0x80) == 0x80
    end

    test "should generate progressive DTD (default)" do
      modeline_str = "44.194 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync"
      modeline = Modeline.parse(modeline_str)

      dtd = DTD.generate(modeline)

      # Bit 7 should be 0 for progressive
      <<_::136, flags::8>> = dtd
      assert Bitwise.band(flags, 0x80) == 0
    end

    test "should handle max h_active (4095)" do
      modeline_str = "44.194 4095 4100 4150 4500 2000 2003 2008 2046 -HSync +Vsync"
      modeline = Modeline.parse(modeline_str)

      dtd = DTD.generate(modeline)
      assert byte_size(dtd) == 18
    end

    test "should handle max h_pulse (1023)" do
      modeline_str = "44.194 3000 3032 4055 4500 2000 2003 2008 2046 -HSync +Vsync"
      modeline = Modeline.parse(modeline_str)

      dtd = DTD.generate(modeline)
      assert byte_size(dtd) == 18
    end
  end
end
