defmodule Edid.EDID do
  @moduledoc """
  Generates EDID binary data from resolution or modeline specifications.

  ## Overview

  This module accepts a list of resolution strings or modeline strings and
  generates complete EDID binary data containing all the specified resolutions.

  ## Input Formats

  ### Resolution Spec
  Format: `WIDTHxHEIGHT@REFRESH_RATE`

  Examples:
  - `"3000x2000@60"`
  - `"1920x1080@90"`
  - `"2560x1440@120"`

  ### Modeline String
  Format: `CLOCK_HZ H_ACTIVE H_SYNC_START H_SYNC_END H_TOTAL V_ACTIVE V_SYNC_START V_SYNC_END V_TOTAL +/-HSync +/-VSync`

  Examples:
  - `"514.00 3000 3240 3568 4136 2000 2003 2013 2072 -HSync +VSync"`
  - `"148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync"`

  ## Output

  Returns a complete EDID binary (128 bytes base block) containing up to 4 DTDs.
  For more than 4 DTDs, extension blocks are used (up to 8 DTDs total).

  ## Examples

      # Generate EDID with multiple resolutions
      edid = Edid.EDID.generate([
        "1920x1080@60",
        "2560x1440@90"
      ])
      File.write!("edid.bin", edid)

      # Generate EDID with modeline strings
      edid = Edid.EDID.generate([
        "514.00 3000 3240 3568 4136 2000 2003 2013 2072 -HSync +VSync"
      ])

      # Generate EDID with mixed formats
      edid = Edid.EDID.generate([
        "1920x1080@60",
        "514.00 3000 3240 3568 4136 2000 2003 2013 2072 -HSync +VSync"
      ])

  """
  alias Edid.DTD
  alias Edid.ExtensionBlock
  alias Edid.Modeline
  alias Edid.Resolution
  alias Edid.Utils

  @typedoc """
  EDID binary.
  """
  @type t :: binary()

  @doc """
  Generates EDID binary from a list of resolution specs or modeline strings.

  ## Parameters

  - `specs` - List of resolution specs or modeline strings

  ## Returns

  - `edid_binary` - 128-byte or 256-byte EDID binary containing DTDs for each specification

  ## Examples

      iex> edid = Edid.EDID.generate(["1920x1080@60"])
      iex> byte_size(edid)
      128

      iex> edid = Edid.EDID.generate([
      ...>   "1920x1080@60",
      ...>   "2560x1440@90"
      ...> ])
      iex> byte_size(edid)
      128

      iex> edid = Edid.EDID.generate([
      ...>   "1920x1080@60",
      ...>   "2560x1440@90",
      ...>   "3000x2000@60",
      ...>   "3840x2160@60",
      ...>   "2560x1600@60"
      ...> ])
      iex> byte_size(edid)
      256

  """
  @spec generate([binary()]) :: t() | no_return()
  def generate(specs)

  def generate(specs) when is_list(specs) do
    specs
    |> Stream.map(&parse_spec/1)
    |> Enum.map(&DTD.generate/1)
    |> do_generate()
  end

  @spec do_generate([DTD.t()]) :: t()
  defp do_generate(dtds) when length(dtds) <= 4 do
    generate_base_edid(dtds, 0)
  end

  defp do_generate(dtds) when length(dtds) > 4 do
    {base_dtds, extension_dtds} = Enum.split(dtds, 4)

    # EDID supports max 1020 DTDs (base block + 255 extension blocks)
    if length(dtds) > 1020 do
      raise ArgumentError,
            "EDID supports maximum 1020 DTDs (base block + 255 extension blocks), but got #{length(dtds)}."
    end

    # Calculate number of extension blocks needed (each holds up to 4 DTDs)
    num_ext_blocks = div(length(extension_dtds) + 3, 4)

    base_edid = generate_base_edid(base_dtds, num_ext_blocks)

    extension_blocks =
      extension_dtds
      |> Enum.chunk_every(4)
      |> Enum.map(&ExtensionBlock.generate/1)

    <<base_edid::binary, Enum.join(extension_blocks, "")::binary>>
  end

  defp do_generate(dtds) do
    raise ArgumentError,
          "EDID supports maximum 1020 DTDs (base block + 255 extension blocks), but got #{length(dtds)}."
  end

  defp generate_base_edid(dtds, extensions) when length(dtds) <= 4 do
    dtds = Enum.take(dtds, 4)
    dtds = dtds ++ List.duplicate(<<0::144>>, 4 - length(dtds))

    manufacturer_id = generate_manufacturer_id("ALX")
    product_code = 0x0539
    serial_number = 0

    {year, week} = :calendar.iso_week_number()
    week = week
    year = year - 1990

    version = 1
    revision = 3

    video_input = 0x6D

    max_width_cm = 10
    max_height_cm = 10

    gamma = 120

    features = 0xEA

    chromaticity = <<0x5E, 0xC0, 0xA4, 0x59, 0x4A, 0x98, 0x25, 0x20, 0x50, 0x54>>

    established_timing = <<0x00, 0x00, 0x00>>

    standard_timing =
      <<0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01>>

    # Build the binary with explicit bit sizes to ensure exactly 127 bytes
    # 126 bytes data + 1 byte extensions = 127 bytes total
    dtd_binary = Enum.reduce(dtds, <<>>, fn dtd, acc -> acc <> dtd end)

    base_block =
      <<0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, manufacturer_id::16,
        product_code::16-little, serial_number::32-little, week::8, year::8, version::8,
        revision::8, video_input::8, max_width_cm::8, max_height_cm::8, gamma::8, features::8,
        chromaticity::binary, established_timing::binary, standard_timing::binary,
        dtd_binary::binary, extensions::8>>

    checksum = Utils.checksum(base_block)
    base_block <> <<checksum::8>>
  end

  @spec generate_manufacturer_id(binary()) :: non_neg_integer()
  defp generate_manufacturer_id(name)

  defp generate_manufacturer_id(name) when byte_size(name) == 3 do
    <<c1, c2, c3>> = String.upcase(name)
    rem((c1 - 64) * 1024 + (c2 - 64) * 32 + (c3 - 64), 65_536)
  end

  @spec parse_spec(binary()) :: Modeline.t() | no_return()
  defp parse_spec(spec)

  defp parse_spec(spec) when is_binary(spec) do
    cond do
      spec =~ ~r/^\s*\d+\.?\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+/ ->
        Modeline.parse(spec)

      spec =~ ~r/^\s*\d+x\d+@\d+\s*$/ ->
        spec
        |> Resolution.parse()
        |> Modeline.from_resolution()

      true ->
        message =
          "Invalid specification format: #{spec}. Expected resolution spec (WIDTHxHEIGHT@REFRESH_RATE) or modeline string."

        raise ArgumentError, message
    end
  end
end
