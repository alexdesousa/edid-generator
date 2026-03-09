defmodule Edid.ExtensionBlockTest do
  use ExUnit.Case, async: true
  doctest Edid.ExtensionBlock

  alias Edid.ExtensionBlock

  describe inspect(&ExtensionBlock.generate/1) do
    test "should generate extension block with 1 DTD" do
      modeline =
        Edid.Modeline.parse("148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync")

      dtd = Edid.DTD.generate(modeline)
      extension_block = ExtensionBlock.generate([dtd])

      assert byte_size(extension_block) == 128
      <<0x02, 0x03, 0x04, byte3::8, d1::144, _::binary>> = extension_block
      assert rem(byte3, 16) == 1
      assert <<d1::144>> == dtd
    end

    test "should generate extension block with 4 DTDs" do
      modelines = [
        "148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync",
        "241.50 2560 2608 2640 2720 1440 1443 1448 1497 -HSync +VSync",
        "332.50 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +VSync",
        "415.00 3840 3888 3920 4000 2160 2163 2168 2222 -HSync +VSync"
      ]

      dtds = Enum.map(modelines, &Edid.Modeline.parse/1)
      dtds = Enum.map(dtds, &Edid.DTD.generate/1)

      extension_block = ExtensionBlock.generate(dtds)

      assert byte_size(extension_block) == 128
    end

    test "should pad extension block with zero DTDs" do
      modeline =
        Edid.Modeline.parse("148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync")

      dtd = Edid.DTD.generate(modeline)
      extension_block = ExtensionBlock.generate([dtd])

      <<_::8, _::8, _::8, _::8, d1::144, d2::144, d3::144, d4::144, _::binary>> =
        extension_block

      assert <<d1::144>> == dtd
      assert <<d2::144>> == <<0::144>>
      assert <<d3::144>> == <<0::144>>
      assert <<d4::144>> == <<0::144>>
    end

    test "should produce valid checksum" do
      modeline =
        Edid.Modeline.parse("148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync")

      dtd = Edid.DTD.generate(modeline)
      extension_block = ExtensionBlock.generate([dtd])

      data = binary_part(extension_block, 0, 127)
      <<checksum::8>> = binary_part(extension_block, 127, 1)

      total =
        data
        |> :binary.bin_to_list()
        |> Enum.sum()

      assert rem(total + checksum, 256) == 0
    end
  end
end
