defmodule Edid.DTD do
  @moduledoc """
  Generates DTD (Detailed Timing Descriptor) binaries.

  Each DTD is 18 bytes and describes one resolution's timing parameters
  as specified in the VESA EDID standard.
  """

  @typedoc """
  DTD (Detailed Timing Descriptor) as 18-byte binary.

  Each DTD describes one resolution's timing parameters.
  """
  @type t :: <<_::144>>

  @doc """
  Generates a DTD (Detailed Timing Descriptor) as 18-byte binary.

  ## Parameters

  - `modeline` - `Edid.Modeline.t()` struct with timing data

  ## DTD Format (18 bytes)

  ```
  Bytes 0-1:  Pixel clock in 10kHz units (little-endian)
  Byte 2:     Horizontal active pixels 8 lsbits
  Byte 3:     Horizontal blanking pixels 8 lsbits
  Byte 4:     Horizontal active 4 msbits (bits 7-4) + horizontal blanking 4 msbits (bits 3-0)
  Byte 5:     Vertical active lines 8 lsbits
  Byte 6:     Vertical blanking lines 8 lsbits
  Byte 7:     Vertical active 4 msbits (bits 7-4) + vertical blanking 4 msbits (bits 3-0)
  Byte 8:     Horizontal front porch (sync offset) pixels 8 lsbits
  Byte 9:     Horizontal sync pulse width pixels 8 lsbits
  Byte 10:    Vertical front porch 4 lsbits (bits 7-4) + vertical sync pulse width 4 lsbits (bits 3-0)
  Byte 11:    Horizontal porch MSBs (bits 7-6) + horizontal pulse MSBs (bits 5-4) +
              vertical porch MSBs (bits 3-2) + vertical pulse MSBs (bits 1-0)
  Byte 12:    Horizontal image size mm 8 lsbits
  Byte 13:    Vertical image size mm 8 lsbits
  Byte 14:    Horizontal image size mm 4 msbits (bits 7-4) + vertical image size mm 4 msbits (bits 3-0)
  Byte 15:    Horizontal border pixels
  Byte 16:    Vertical border lines
  Byte 17:    Features bitmap (bit 7=interlaced, bits 6-5=stereo, bit 4=digital, bit 3=separate sync, bit 2=V sync polarity, bit 1=H sync polarity, bit 0=stereo bit0)
  ```

  ## Examples

      iex> modeline = Edid.Modeline.parse("441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync")
      iex> dtd = Edid.DTD.generate(modeline)
      iex> byte_size(dtd)
      18
  """
  @spec generate(Edid.Modeline.t()) :: t()
  def generate(modeline)

  def generate(%Edid.Modeline{} = modeline) do
    blanking = Edid.Blanking.calculate(modeline)

    clock = modeline.clock
    h_active = modeline.h_active
    v_active = modeline.v_active
    h_blanking = blanking.h_blanking
    v_blanking = blanking.v_blanking
    h_offset = blanking.h_offset
    v_offset = blanking.v_offset
    h_pulse = blanking.h_pulse
    h_sync_polarity = modeline.h_sync_polarity
    v_sync_polarity = modeline.v_sync_polarity
    interlaced_bit = modeline.interlaced

    h_size_mm = 100
    v_size_mm = 100
    h_border = 0
    v_border = 0
    stereo_mode = 0

    clock_le = <<div(clock, 10)::16-little>>

    h_active_lsb = Bitwise.band(h_active, 0xFF)
    h_blanking_lsb = Bitwise.band(h_blanking, 0xFF)

    h_msbs =
      <<Bitwise.band(Bitwise.bsr(h_active, 8), 0xF)::4,
        Bitwise.band(Bitwise.bsr(h_blanking, 8), 0xF)::4>>

    v_active_lsb = Bitwise.band(v_active, 0xFF)
    v_blanking_lsb = Bitwise.band(v_blanking, 0xFF)

    v_msbs =
      <<Bitwise.band(Bitwise.bsr(v_active, 8), 0xF)::4,
        Bitwise.band(Bitwise.bsr(v_blanking, 8), 0xF)::4>>

    h_offset_lsb = Bitwise.band(h_offset, 0xFF)
    h_pulse_lsb = Bitwise.band(h_pulse, 0xFF)

    v_offset_lsb = Bitwise.band(v_offset, 0xF)
    v_pulse_lsb = Bitwise.band(v_blanking, 0xF)

    byte10 = <<v_offset_lsb::4, v_pulse_lsb::4>>

    h_offset_msb_2b = Bitwise.band(Bitwise.bsr(h_offset, 2), 0x3)
    h_pulse_msb_2b = Bitwise.band(Bitwise.bsr(h_pulse, 2), 0x3)
    v_offset_msb_2b = Bitwise.band(Bitwise.bsr(v_offset, 4), 0x3)
    v_pulse_msb_2b = Bitwise.band(Bitwise.bsr(v_blanking, 4), 0x3)

    byte11 =
      <<h_offset_msb_2b::2, h_pulse_msb_2b::2, v_offset_msb_2b::2, v_pulse_msb_2b::2>>

    h_size_mm_lsb = Bitwise.band(h_size_mm, 0xFF)
    v_size_mm_lsb = Bitwise.band(v_size_mm, 0xFF)

    h_size_mm_msb_4b = Bitwise.band(Bitwise.bsr(h_size_mm, 8), 0xF)
    v_size_mm_msb_4b = Bitwise.band(Bitwise.bsr(v_size_mm, 8), 0xF)

    byte14 =
      <<h_size_mm_msb_4b::4, v_size_mm_msb_4b::4>>

    digital = 1
    separate = 1
    stereo_mode_bit0 = Bitwise.band(stereo_mode, 0x1)

    features =
      <<interlaced_bit::1, stereo_mode::2, digital::1, separate::1, v_sync_polarity::1,
        h_sync_polarity::1, stereo_mode_bit0::1>>

    <<clock_le::binary, h_active_lsb::8, h_blanking_lsb::8, h_msbs::binary, v_active_lsb::8,
      v_blanking_lsb::8, v_msbs::binary, h_offset_lsb::8, h_pulse_lsb::8, byte10::binary,
      byte11::binary, h_size_mm_lsb::8, v_size_mm_lsb::8, byte14::binary, h_border::8,
      v_border::8, features::binary>>
  end
end
