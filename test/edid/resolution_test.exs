defmodule Edid.ResolutionTest do
  use ExUnit.Case, async: true
  doctest Edid.Resolution

  alias Edid.Resolution

  describe inspect(&Resolution.parse/1) do
    test "should parse basic resolution spec correctly" do
      spec = "1920x1080@60"
      resolution = Resolution.parse(spec)

      assert resolution.width == 1_920
      assert resolution.height == 1_080
      assert resolution.refresh == 60
    end

    test "should handle different refresh rates" do
      resolution_60 = Resolution.parse("1920x1080@60")
      resolution_90 = Resolution.parse("1920x1080@90")

      assert resolution_60.refresh < resolution_90.refresh
    end

    test "should handle higher resolutions" do
      resolution = Resolution.parse("3000x2000@60")

      assert resolution.width == 3_000
      assert resolution.height == 2_000
      assert resolution.refresh == 60
    end

    test "should handle 4K resolution" do
      resolution = Resolution.parse("3840x2160@60")

      assert resolution.width == 3_840
      assert resolution.height == 2_160
      assert resolution.refresh == 60
    end

    test "should handle 4K at 120Hz" do
      resolution = Resolution.parse("3840x2160@120")

      assert resolution.width == 3_840
      assert resolution.height == 2_160
      assert resolution.refresh == 120
    end

    test "should raise on empty string" do
      assert_raise ArgumentError, fn ->
        Resolution.parse("")
      end
    end

    test "should raise on invalid format" do
      assert_raise ArgumentError, fn ->
        Resolution.parse("invalid")
      end
    end

    test "should raise on missing refresh rate" do
      assert_raise ArgumentError, fn ->
        Resolution.parse("1920x1080")
      end
    end

    test "should raise on missing height" do
      assert_raise ArgumentError, fn ->
        Resolution.parse("1920@60")
      end
    end

    test "should raise on missing width" do
      assert_raise ArgumentError, fn ->
        Resolution.parse("x1080@60")
      end
    end

    test "should raise on zero width" do
      assert_raise ArgumentError, fn ->
        Resolution.parse("0x1080@60")
      end
    end

    test "should raise on zero height" do
      assert_raise ArgumentError, fn ->
        Resolution.parse("1920x0@60")
      end
    end

    test "should raise on zero refresh rate" do
      assert_raise ArgumentError, fn ->
        Resolution.parse("1920x1080@0")
      end
    end

    test "should raise on negative values" do
      assert_raise ArgumentError, fn ->
        Resolution.parse("-1920x1080@60")
      end
    end
  end
end
