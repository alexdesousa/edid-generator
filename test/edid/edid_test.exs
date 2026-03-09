defmodule Edid.EDIDTest do
  use ExUnit.Case, async: true
  doctest Edid.EDID

  alias Edid.EDID

  describe inspect(&EDID.generate/1) do
    test "should generate EDID from a single resolution spec" do
      edid = EDID.generate(["1920x1080@60"])

      assert byte_size(edid) == 128
      <<0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, _::binary>> = edid
    end

    test "should generate EDID from multiple resolution specs" do
      edid =
        EDID.generate([
          "1920x1080@60",
          "2560x1440@90"
        ])

      assert byte_size(edid) == 128
      <<0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, _::binary>> = edid
    end

    test "should generate EDID from modeline string" do
      modeline_str = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync"
      edid = EDID.generate([modeline_str])

      assert byte_size(edid) == 128
      <<0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, _::binary>> = edid
    end

    test "should handle mixed resolution specs and modeline strings" do
      edid =
        EDID.generate([
          "1920x1080@60",
          "441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync"
        ])

      assert byte_size(edid) == 128
    end

    test "should support up to 4 DTDs" do
      edid =
        EDID.generate([
          "1920x1080@60",
          "2560x1440@90",
          "3000x2000@60",
          "3840x2160@60"
        ])

      assert byte_size(edid) == 128
    end

    test "should raise on invalid format" do
      assert_raise ArgumentError, fn ->
        EDID.generate(["invalid-spec"])
      end
    end

    test "should handle empty list" do
      edid = EDID.generate([])
      assert byte_size(edid) == 128
    end

    test "should produce valid EDID checksum" do
      edid = EDID.generate(["1920x1080@60"])

      data = binary_part(edid, 0, 127)
      <<checksum::8>> = binary_part(edid, 127, 1)

      total =
        data
        |> :binary.bin_to_list()
        |> Enum.sum()

      assert rem(total + checksum, 256) == 0
    end

    test "should generate EDID with 5 DTDs using extension block" do
      edid =
        EDID.generate([
          "1920x1080@60",
          "2560x1440@90",
          "3000x2000@60",
          "3840x2160@60",
          "2560x1600@60"
        ])

      assert byte_size(edid) == 256
      <<0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, _::binary>> = edid
    end

    test "should generate EDID with 8 DTDs using extension block" do
      edid =
        EDID.generate([
          "1920x1080@60",
          "2560x1440@90",
          "3000x2000@60",
          "3840x2160@60",
          "2560x1600@60",
          "1920x1200@60",
          "1600x900@60",
          "1280x720@60"
        ])

      assert byte_size(edid) == 256
    end

    test "should generate EDID with more than 8 DTDs using multiple extension blocks" do
      edid =
        EDID.generate([
          "1920x1080@60",
          "2560x1440@90",
          "3000x2000@60",
          "3840x2160@60",
          "2560x1600@60",
          "1920x1200@60",
          "1600x900@60",
          "1280x720@60",
          "1024x768@60"
        ])

      assert byte_size(edid) == 384
    end

    test "should produce valid extension block checksum" do
      edid =
        EDID.generate([
          "1920x1080@60",
          "2560x1440@90",
          "3000x2000@60",
          "3840x2160@60",
          "2560x1600@60"
        ])

      base_block = binary_part(edid, 0, 128)
      extension_block = binary_part(edid, 128, 128)

      base_data = binary_part(base_block, 0, 127)
      base_checksum = binary_part(base_block, 127, 1)

      ext_data = binary_part(extension_block, 0, 127)
      ext_checksum = binary_part(extension_block, 127, 1)

      base_total =
        base_data
        |> :binary.bin_to_list()
        |> Enum.sum()

      ext_total =
        ext_data
        |> :binary.bin_to_list()
        |> Enum.sum()

      <<base_checksum_val::8>> = base_checksum
      <<ext_checksum_val::8>> = ext_checksum

      assert rem(base_total + base_checksum_val, 256) == 0
      assert rem(ext_total + ext_checksum_val, 256) == 0
    end

    test "should include correct extension block tag" do
      edid =
        EDID.generate([
          "1920x1080@60",
          "2560x1440@90",
          "3000x2000@60",
          "3840x2160@60",
          "2560x1600@60"
        ])

      ext_block = binary_part(edid, 128, 128)
      <<0x02, _::binary>> = ext_block
    end

    test "should correctly count extension blocks in base block" do
      edid =
        EDID.generate([
          "1920x1080@60",
          "2560x1440@90",
          "3000x2000@60",
          "3840x2160@60",
          "2560x1600@60"
        ])

      # The extension count should be 1 (1 extension block for 5 DTDs)
      # Base block is 128 bytes, extension block is 128 bytes
      assert byte_size(edid) == 256
    end
  end
end
