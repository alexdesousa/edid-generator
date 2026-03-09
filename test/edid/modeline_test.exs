defmodule Edid.ModelineTest do
  use ExUnit.Case, async: true
  doctest Edid.Modeline

  alias Edid.Modeline
  alias Edid.Resolution

  describe inspect(&Modeline.to_string/1) do
    test "should convert from a struct to a string" do
      modeline_str = "514.0 3000 3240 3568 4136 2000 2003 2013 2072 -HSync +VSync"
      modeline = Modeline.parse(modeline_str)
      assert ^modeline_str = Modeline.to_string(modeline)
    end
  end

  describe inspect(&Modeline.from_resolution/1) do
    test "should convert from a resolution to a modeline struct" do
      modeline_str = "514.0 3000 3240 3568 4136 2000 2003 2013 2072 -HSync +VSync"

      resolution = Resolution.parse("3000x2000@60")
      modeline = Modeline.from_resolution(resolution)
      assert ^modeline_str = Modeline.to_string(modeline)
    end

    test "should convert different resolutions correctly" do
      # 1920x1080@60 (Full HD)
      resolution = Resolution.parse("1920x1080@60")
      modeline = Modeline.from_resolution(resolution)

      assert modeline.h_active == 1920
      assert modeline.v_active == 1080
      assert modeline.h_total > modeline.h_active
      assert modeline.v_total > modeline.v_active
      assert modeline.clock > 0
    end

    test "should handle different refresh rates" do
      resolution_60 = Resolution.parse("1920x1080@60")
      resolution_90 = Resolution.parse("1920x1080@90")
      resolution_120 = Resolution.parse("1920x1080@120")

      modeline_60 = Modeline.from_resolution(resolution_60)
      modeline_90 = Modeline.from_resolution(resolution_90)
      modeline_120 = Modeline.from_resolution(resolution_120)

      assert modeline_60.clock < modeline_90.clock
      assert modeline_90.clock < modeline_120.clock
    end

    test "should set correct sync polarities (defaults)" do
      resolution = Resolution.parse("1920x1080@60")
      modeline = Modeline.from_resolution(resolution)

      # negative
      assert modeline.h_sync_polarity == 0
      # positive
      assert modeline.v_sync_polarity == 1
    end

    test "should calculate reasonable timing values" do
      resolution = Resolution.parse("3000x2000@60")
      modeline = Modeline.from_resolution(resolution)

      # Verify the values are within valid EDID ranges
      assert modeline.clock > 0
      assert modeline.h_active == 3000
      assert modeline.v_active == 2000
      assert modeline.h_total > modeline.h_active
      assert modeline.v_total > modeline.v_active
      assert modeline.h_sync_start > modeline.h_active
      assert modeline.h_sync_end > modeline.h_sync_start
      assert modeline.h_sync_end <= modeline.h_total
      assert modeline.v_sync_start > modeline.v_active
      assert modeline.v_sync_end > modeline.v_sync_start
      assert modeline.v_sync_end <= modeline.v_total
      assert modeline.h_total <= 8191
      assert modeline.v_total <= 8191
    end

    test "should generate correct modelines matching cvt for common resolutions" do
      # Test 1280x720@60
      resolution = Resolution.parse("1280x720@60")
      modeline = Modeline.from_resolution(resolution)

      assert Edid.Modeline.to_string(modeline) ==
               "74.5 1280 1344 1472 1664 720 723 728 748 -HSync +VSync"

      # Test 1920x1080@60
      resolution = Resolution.parse("1920x1080@60")
      modeline = Modeline.from_resolution(resolution)

      assert Edid.Modeline.to_string(modeline) ==
               "173.0 1920 2048 2248 2576 1080 1083 1088 1120 -HSync +VSync"

      # Test 2560x1440@60
      resolution = Resolution.parse("2560x1440@60")
      modeline = Modeline.from_resolution(resolution)

      assert Edid.Modeline.to_string(modeline) ==
               "312.25 2560 2752 3024 3488 1440 1443 1448 1493 -HSync +VSync"

      # Test 640x480@60
      resolution = Resolution.parse("640x480@60")
      modeline = Modeline.from_resolution(resolution)

      assert Edid.Modeline.to_string(modeline) ==
               "23.75 640 656 720 800 480 483 487 500 -HSync +VSync"

      # Test 800x600@60
      resolution = Resolution.parse("800x600@60")
      modeline = Modeline.from_resolution(resolution)

      assert Edid.Modeline.to_string(modeline) ==
               "38.25 800 832 912 1024 600 603 607 624 -HSync +VSync"

      # Test 1024x768@60
      resolution = Resolution.parse("1024x768@60")
      modeline = Modeline.from_resolution(resolution)

      assert Edid.Modeline.to_string(modeline) ==
               "63.5 1024 1072 1176 1328 768 771 775 798 -HSync +VSync"
    end
  end

  describe inspect(&Modeline.parse/1) do
    test "should parse basic modeline correctly" do
      modeline_str = "514.00 3000 3240 3568 4136 2000 2003 2013 2072 -HSync +VSync"
      modeline = Modeline.parse(modeline_str)

      assert modeline.clock == 514_000
      assert modeline.h_active == 3_000
      assert modeline.h_sync_start == 3_240
      assert modeline.h_sync_end == 3_568
      assert modeline.h_total == 4_136
      assert modeline.v_active == 2_000
      assert modeline.v_sync_start == 2_003
      assert modeline.v_sync_end == 2_013
      assert modeline.v_total == 2_072
      assert modeline.h_sync_polarity == 0
      assert modeline.v_sync_polarity == 1
    end

    test "should handle positive HSync and VSync" do
      modeline_str = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 +HSync +Vsync"
      modeline = Modeline.parse(modeline_str)

      assert modeline.h_sync_polarity == 1
      assert modeline.v_sync_polarity == 1
    end

    test "should handle mixed polarities" do
      modeline_str = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 +HSync -Vsync"
      modeline = Modeline.parse(modeline_str)

      assert modeline.h_sync_polarity == 1
      assert modeline.v_sync_polarity == 0
    end

    test "should work without sync flags" do
      modeline_str = "441.94 3000 3032 3064 3600 2000 2003 2008 2046"
      modeline = Modeline.parse(modeline_str)

      assert modeline.h_sync_polarity == 1
      assert modeline.v_sync_polarity == 1
      assert modeline.interlaced == 0
    end

    test "should parse Interlace flag" do
      modeline_str = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync Interlace"
      modeline = Modeline.parse(modeline_str)

      assert modeline.h_sync_polarity == 0
      assert modeline.v_sync_polarity == 1
      assert modeline.interlaced == 1
    end

    test "should default to non-interlaced" do
      modeline_str = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync"
      modeline = Modeline.parse(modeline_str)

      assert modeline.interlaced == 0
    end

    test "should handle mixed polarities with Interlace" do
      modeline_str = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 +HSync -Vsync Interlace"
      modeline = Modeline.parse(modeline_str)

      assert modeline.h_sync_polarity == 1
      assert modeline.v_sync_polarity == 0
      assert modeline.interlaced == 1
    end

    test "should handle whitespace variations" do
      modeline_str = "  441.94 3000 3032 3064 3600 2000 2003 2008 2046 +HSync -Vsync  "
      modeline = Modeline.parse(modeline_str)

      modeline_str = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 +HSync -Vsync"
      assert ^modeline = Modeline.parse(modeline_str)
    end

    test "should raise on empty string" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("")
      end
    end

    test "should raise on invalid modeline" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("Invalid")
      end
    end

    test "should raise on invalid clock value (zero)" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("0 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise on invalid clock value (negative)" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("-10 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise on too-high clock value" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("1000 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise when h_sync_start >= h_total" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("441.94 3000 3600 3064 3600 2000 2003 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise when h_sync_end > h_total" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("441.94 3000 3032 3601 3600 2000 2003 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise when v_sync_start >= v_total" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("441.94 3000 3032 3064 3600 2000 2046 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise when v_sync_end > v_total" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("441.94 3000 3032 3064 3600 2000 2003 2050 2046 -HSync +Vsync")
      end
    end

    test "should raise when h_active is zero" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("441.94 0 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise when h_active exceeds maximum" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("441.94 4096 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise when v_active is zero" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("441.94 3000 3032 3064 3600 0 2003 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise when v_active exceeds maximum" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("441.94 3000 3032 3064 3600 4096 2003 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise when h_total exceeds maximum" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("441.94 3000 3032 3064 8192 2000 2003 2008 2046 -HSync +Vsync")
      end
    end

    test "should raise when v_total exceeds maximum" do
      assert_raise ArgumentError, fn ->
        Modeline.parse("441.94 3000 3032 3064 3600 2000 2003 2008 8192 -HSync +Vsync")
      end
    end

    test "should convert interlaced modeline to string and back" do
      modeline_str = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +VSync Interlace"
      modeline = Modeline.parse(modeline_str)
      assert ^modeline_str = Modeline.to_string(modeline)
    end
  end
end
