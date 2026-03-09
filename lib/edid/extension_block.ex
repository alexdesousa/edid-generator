defmodule Edid.ExtensionBlock do
  @moduledoc """
  Generates EDID extension blocks for supporting more than 4 DTDs.

  EDID extension blocks are 128-byte blocks that follow the base block.
  Each extension block can contain up to 4 DTDs (Detailed Timing Descriptors).

  ## Extension Block Types

  This module currently supports the **Timing Extension (Type 0x02)**,
  which provides additional DTDs beyond the 4 available in the base block.
  """
  alias Edid.DTD
  alias Edid.Utils

  @typedoc """
  An EDID extension block.
  """
  @type t :: binary()

  @doc """
  Generates an extension block with up to 4 DTDs.

  ## Parameters

  - `dtds` - List of DTD binaries (max 4)

  ## Returns

  - 128-byte extension block binary

  ## Example

      dtds = [
        <<...::144>>,
        <<...::144>>
      ]

      extension_block = Edid.ExtensionBlock.generate(dtds)

  """
  @spec generate([DTD.t()]) :: t()
  def generate(dtds) when length(dtds) <= 4 do
    dtds = Enum.take(dtds, 4)

    original_length = length(dtds)
    dtds = dtds ++ List.duplicate(<<0::144>>, 4 - original_length)

    extension_tag = 0x02
    version = 0x03
    dtd_offset = 0x04
    native_dtd_count = original_length

    flags = if List.first(dtds) != <<0::144>>, do: 0x80, else: 0

    byte3 = Bitwise.bor(flags, native_dtd_count)

    dtd_data = Enum.reduce(dtds, <<>>, fn dtd, acc -> acc <> dtd end)
    padding_size = 127 - 4 - byte_size(dtd_data)
    padding = List.duplicate(0, padding_size) |> :binary.list_to_bin()

    data_part =
      <<extension_tag::8, version::8, dtd_offset::8, byte3::8, dtd_data::binary, padding::binary>>

    <<data_part::binary, Utils.checksum(data_part)::8>>
  end
end
