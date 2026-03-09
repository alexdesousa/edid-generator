defmodule Edid do
  @moduledoc """
  EDID (Extended Display Identification Data) file generator.

  This module provides a simple interface to generate EDID binary files from
  resolution specifications or modeline strings.

  ## EDID Overview

  EDID is a data structure that allows display devices to communicate their
  capabilities to graphics adapters. It's commonly used to generate custom
  display modes for monitors that don't report proper EDID information.

  ## Input Formats

  ### Resolution Spec
  Format: `WIDTHxHEIGHT@REFRESH_RATE`

  Examples:
  - `"1920x1080@60"` (Full HD at 60Hz)
  - `"2560x1440@90"` (QHD at 90Hz)
  - `"3840x2160@60"` (4K UHD at 60Hz)

  ### Modeline String
  Format: `CLOCK_HZ H_ACTIVE H_SYNC_START H_SYNC_END H_TOTAL V_ACTIVE V_SYNC_START V_SYNC_END V_TOTAL +/-HSync +/-VSync [Interlace]`

  Examples:
  - `"148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync"`
  - `"241.50 2560 2608 2640 2720 1440 1443 1448 1497 -HSync +VSync"`
  - `"441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +VSync Interlace"`
  - `"441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +VSync Interlace"`

  ## Examples

      # Generate EDID with multiple resolutions
      Edid.generate("edid.bin", "1920x1080@60, 2560x1440@90")

      # Generate EDID with modeline strings
      Edid.generate("custom.edid", "148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync")

      # Mix resolution specs and modelines
      Edid.generate("hybrid.bin", "1920x1080@60, 148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync")

  """

  @doc """
  Generates an EDID file from resolution specifications.

  ## Parameters

  - `filename` - Path to the output EDID file. EDID files typically use `.bin`
    extension.
  - `spec` - Comma-separated resolution specifications and/or modeline strings.
    Up to 1020 DTDs (765 resolutions) are supported, split across the base
    block (4 DTDs) and up to 255 extension blocks.

  ## Examples

      Edid.generate("edid.bin", "1920x1080@60, 2560x1440@90")

  """
  @spec generate(Path.t(), binary()) :: :ok | no_return()
  def generate(filename, spec)

  def generate(filename, spec)
      when is_binary(filename) and is_binary(spec) do
    spec
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Edid.EDID.generate()
    |> then(&File.write!(filename, &1))
  end
end
