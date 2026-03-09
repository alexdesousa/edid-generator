defmodule Edid.Blanking do
  @moduledoc """
  Calculates blanking parameters from modeline data.

  Blanking parameters are derived from the modeline timing values and
  are used to generate DTDs (Detailed Timing Descriptors).
  """

  @typedoc """
  Blanking parameters.

  ## Fields

  - `:h_blanking` - Horizontal blanking pixels (h_total - h_active)
  - `:v_blanking` - Vertical blanking lines (v_total - v_active)
  - `:h_offset` - Horizontal sync offset (h_sync_start - h_active)
  - `:v_offset` - Vertical sync offset (v_sync_start - v_active)
  - `:h_pulse` - Horizontal sync pulse width (h_sync_end - h_sync_start)
  - `:v_pulse` - Vertical sync pulse width (v_sync_end - v_sync_start)
  """
  @type t :: %__MODULE__{
          h_blanking: h_blanking :: pos_integer(),
          v_blanking: v_blanking :: pos_integer(),
          h_offset: h_offset :: pos_integer(),
          v_offset: v_offset :: pos_integer(),
          h_pulse: h_pulse :: pos_integer(),
          v_pulse: v_pulse :: pos_integer()
        }

  @doc """
  Blanking parameters struct.
  """
  defstruct [
    :h_blanking,
    :v_blanking,
    :h_offset,
    :v_offset,
    :h_pulse,
    :v_pulse
  ]

  @doc """
  Calculates blanking parameters from modeline data.

  ## Parameters

  - `modeline` - The parsed modeline data map or struct

  ## Returns

  A `Edid.Blanking.t()` struct containing blanking parameters.

  ## Examples

      iex> modeline = Edid.Modeline.parse("441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync")
      iex> blanking = Edid.Blanking.calculate(modeline)
      iex> blanking.h_blanking
      600
      iex> blanking.v_blanking
      46

  """
  @spec calculate(Edid.Modeline.t()) :: t()
  def calculate(modeline)

  def calculate(%Edid.Modeline{
        h_total: h_total,
        h_active: h_active,
        h_sync_start: h_sync_start,
        h_sync_end: h_sync_end,
        v_total: v_total,
        v_active: v_active,
        v_sync_start: v_sync_start,
        v_sync_end: v_sync_end
      }) do
    %__MODULE__{
      h_blanking: h_total - h_active,
      v_blanking: v_total - v_active,
      h_offset: h_sync_start - h_active,
      v_offset: v_sync_start - v_active,
      h_pulse: h_sync_end - h_sync_start,
      v_pulse: v_sync_end - v_sync_start
    }
  end
end
