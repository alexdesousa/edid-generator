defmodule Edid.Modeline do
  @moduledoc """
  This module defines a modeline data structure.
  """

  @typedoc """
  Modeline.
  """
  @type t :: %__MODULE__{
          clock: clock :: pos_integer(),
          h_active: h_active :: pos_integer(),
          h_sync_start: h_sync_start :: pos_integer(),
          h_sync_end: h_sync_end :: pos_integer(),
          h_sync_polarity: h_sync_polarity :: non_neg_integer(),
          h_total: h_total :: pos_integer(),
          v_active: v_active :: pos_integer(),
          v_sync_start: v_sync_start_ :: pos_integer(),
          v_sync_end: v_sync_end :: pos_integer(),
          v_sync_polarity: v_sync_polarity :: non_neg_integer(),
          v_total: v_total :: pos_integer(),
          interlaced: interlaced :: non_neg_integer()
        }

  @doc """
  Modeline.
  """
  defstruct [
    :clock,
    :h_active,
    :h_sync_start,
    :h_sync_end,
    :h_sync_polarity,
    :h_total,
    :v_active,
    :v_sync_start,
    :v_sync_end,
    :v_sync_polarity,
    :v_total,
    :interlaced
  ]

  @doc """
  Converts a modeline struct to a modeline string.

  ## Parameters

  - `modeline` - `Edid.Modeline.t()` struct

  ## Returns

  Modeline string in format: "clock h_active h_sync_start h_sync_end h_total v_active v_sync_start v_sync_end v_total +/-HSync +/-VSync [Interlace]"

  ## Examples

      iex> modeline = %Edid.Modeline{
      ...>   clock: 148_500,
      ...>   h_active: 1920,
      ...>   h_sync_start: 2008,
      ...>   h_sync_end: 2052,
      ...>   h_total: 2200,
      ...>   v_active: 1080,
      ...>   v_sync_start: 1083,
      ...>   v_sync_end: 1088,
      ...>   v_total: 1125,
      ...>   h_sync_polarity: 0,
      ...>   v_sync_polarity: 1,
      ...>   interlaced: 0
      ...> }
      iex> Edid.Modeline.to_string(modeline)
      "148.5 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync"

  """
  @spec to_string(t()) :: binary()
  def to_string(%__MODULE__{
        clock: clock,
        h_active: h_active,
        h_sync_start: h_sync_start,
        h_sync_end: h_sync_end,
        h_total: h_total,
        v_active: v_active,
        v_sync_start: v_sync_start,
        v_sync_end: v_sync_end,
        v_total: v_total,
        h_sync_polarity: h_sync_polarity,
        v_sync_polarity: v_sync_polarity,
        interlaced: interlaced
      }) do
    clock_mhz = clock / 1000

    h_sync_flag = if h_sync_polarity == 0, do: "-HSync", else: "+HSync"
    v_sync_flag = if v_sync_polarity == 0, do: "-VSync", else: "+VSync"
    interlace_flag = if interlaced == 1, do: "Interlace", else: nil

    formatted_clock =
      clock_mhz
      |> Float.round(3)
      |> Float.to_string()

    [
      formatted_clock,
      Integer.to_string(h_active),
      Integer.to_string(h_sync_start),
      Integer.to_string(h_sync_end),
      Integer.to_string(h_total),
      Integer.to_string(v_active),
      Integer.to_string(v_sync_start),
      Integer.to_string(v_sync_end),
      Integer.to_string(v_total),
      h_sync_flag,
      v_sync_flag,
      interlace_flag
    ]
    |> Stream.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  @doc """
  Converts a resolution to a modeline struct.

  ## Notes

  This function uses the VESA CVT v1.1 (Coordinated Video Timing) standard algorithm.
  This matches the output of the Linux `cvt` command.

  ### Algorithm

  1. **Horizontal blanking**: Calculated using CVT duty cycle formula
     - `h_period_est` based on refresh rate and vertical timing
     - `ideal_duty_cycle = 30 - 300 × h_period_est / 1000`
     - `h_blank` rounded to nearest 8 pixels (cell granularity)
     - `h_total = h_active + h_blank`

  2. **Vertical blanking**: Calculated from CVT formula
     - `v_sync_bp = 550 / h_period_est`, rounded down + 1
     - `v_total = v_active + v_sync_bp + 3`

  3. **Pixel clock**: Calculated and rounded to 0.25 MHz steps
     - `clock_mhz = h_total / h_period_est`
     - `clock_khz = round(clock_mhz × 1000)`

  4. **Sync timing**:
     - `h_sync = 8% of h_total`, rounded to nearest 8 pixels
     - `h_sync_start = h_active + front_porch`
     - `v_sync_start = v_active + 3` (fixed front porch)

  For exact compatibility with `cvt` command outputs, use the modeline
  directly instead of generating from resolution.
  """
  @spec from_resolution(Edid.Resolution.t()) :: t()
  def from_resolution(resolution)

  def from_resolution(%Edid.Resolution{} = rez) do
    # CVT v1.1 constants (default/cvt behavior)
    cell_gran = 8.0
    # µs
    min_vsync_bp = 550.0
    # lines
    min_v_bporch = 6.0
    # lines
    min_v_porch_rnd = 3.0
    # blanking formula gradient
    m = 600.0
    # blanking formula offset
    c = 40.0
    # blanking formula scaling factor
    k = 128.0
    # blanking formula scaling factor
    j = 20.0
    # MHz
    clock_step = 0.250
    # % of horizontal image
    h_sync_per = 8.0

    # Convert refresh to Hz
    refresh_hz = rez.refresh

    # 1. Round horizontal pixels to cell granularity
    h_pixels_rnd = :math.floor(rez.width / cell_gran) * cell_gran

    # 2. Round vertical lines (no interlacing support yet)
    v_lines_rnd = :math.floor(rez.height)

    # 3. Calculate vertical sync + back porch in lines
    # h_period_est = ((1/v_field_rate_rqd) - MIN_VSYNC_BP/1000000) / (v_lines + MIN_V_PORCH_RND) * 1000000
    h_period_est =
      (1 / refresh_hz - min_vsync_bp / 1_000_000) /
        (v_lines_rnd + min_v_porch_rnd) *
        1_000_000

    # v_sync_bp = MIN_VSYNC_BP / h_period_est
    v_sync_bp = min_vsync_bp / h_period_est

    # v_sync values from CVT spec based on aspect ratio

    # v_sync values from CVT spec based on aspect ratio (with cell granularity)

    v_sync =
      cond do
        # 4:3
        h_pixels_rnd == :math.floor(v_lines_rnd * 4.0 / 3.0 / cell_gran) * cell_gran ->
          4

        # 16:9
        h_pixels_rnd == :math.floor(v_lines_rnd * 16.0 / 9.0 / cell_gran) * cell_gran ->
          5

        # 16:10
        h_pixels_rnd == :math.floor(v_lines_rnd * 16.0 / 10.0 / cell_gran) * cell_gran ->
          6

        # 5:4
        h_pixels_rnd == :math.floor(v_lines_rnd * 5.0 / 4.0 / cell_gran) * cell_gran ->
          7

        # 15:9
        h_pixels_rnd == :math.floor(v_lines_rnd * 15.0 / 9.0 / cell_gran) * cell_gran ->
          7

        # Custom/unknown → default to 10
        true ->
          10
      end

    # Round down and add 1, then clamp to v_sync + min_v_bporch
    v_sync_bp = :math.floor(v_sync_bp) + 1
    v_sync_bp = if v_sync_bp < v_sync + min_v_bporch, do: v_sync + min_v_bporch, else: v_sync_bp

    # 4. Calculate total vertical lines
    # total_v_lines = v_lines + v_sync_bp + MIN_V_PORCH_RND
    total_v_lines = v_lines_rnd + v_sync_bp + min_v_porch_rnd

    # 5. Calculate ideal blanking duty cycle
    # C' = ((C - J) * K/256) + J = ((40 - 20) * 128/256) + 20 = 30
    # M' = M * K/256 = 600 * 128/256 = 300
    # = 30
    c_prime = (c - j) * k / 256 + j
    # = 300
    m_prime = m * k / 256

    ideal_duty_cycle = c_prime - m_prime * h_period_est / 1000

    # 6. Calculate horizontal blanking
    # h_blank = round(total_active_pixels * duty_cycle / (100 - duty_cycle) / (2*cell_gran)) * (2*cell_gran)
    duty_cycle = if ideal_duty_cycle < 20, do: 20, else: ideal_duty_cycle

    h_blank =
      :math.floor(h_pixels_rnd * duty_cycle / (100 - duty_cycle) / (2 * cell_gran)) *
        (2 * cell_gran)

    # 7. Calculate total pixels
    total_pixels = h_pixels_rnd + h_blank

    # 8. Calculate pixel clock
    # MHz
    act_pixel_freq = total_pixels / h_period_est

    # Round to clock step
    rounded_freq = :math.floor(act_pixel_freq / clock_step) * clock_step

    # Clock in kHz
    clock = round(rounded_freq * 1000)

    # 9. Calculate h_sync length
    h_sync = :math.floor(h_sync_per / 100 * total_pixels / cell_gran) * cell_gran

    # 10. Calculate positions
    # h_blank / 2 = back porch
    h_back_porch = h_blank / 2
    # h_front_porch = h_blank - h_back_porch - h_sync
    h_front_porch = h_blank - h_back_porch - h_sync

    h_total = round(total_pixels)
    h_active = round(h_pixels_rnd)
    h_sync_start = round(h_pixels_rnd + h_front_porch)
    h_sync_end = round(h_pixels_rnd + h_front_porch + h_sync)

    v_total = round(total_v_lines)
    v_active = round(v_lines_rnd)
    v_sync_start = round(v_lines_rnd + min_v_porch_rnd)
    # v_sync length = v_sync (from earlier calculation, rounded)
    v_sync_len = round(v_sync)
    v_sync_end = round(v_lines_rnd + min_v_porch_rnd + v_sync_len)

    %Edid.Modeline{
      clock: clock,
      h_active: h_active,
      h_sync_start: h_sync_start,
      h_sync_end: h_sync_end,
      h_total: h_total,
      v_active: v_active,
      v_sync_start: v_sync_start,
      v_sync_end: v_sync_end,
      v_total: v_total,
      h_sync_polarity: 0,
      v_sync_polarity: 1,
      interlaced: 0
    }
  end

  @doc """
  Parses a modeline string.

  ## Usage

  ```elixir
  iex> modeline = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync"
  iex> Edid.Modeline.parse(modeline)
  %Edid.Modeline{
    clock: 441_940,
    h_active: 3_000,
    h_sync_start: 3_032,
    h_sync_end: 3_064,
    h_total: 3_600,
    v_active: 2_000,
    v_sync_start: 2_003,
    v_sync_end: 2_008,
    v_total: 2_046,
    h_sync_polarity: 0,
    v_sync_polarity: 1,
    interlaced: 0
  }

  iex> modeline = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync Interlace"
  iex> Edid.Modeline.parse(modeline)
  %Edid.Modeline{
    clock: 441_940,
    h_active: 3_000,
    h_sync_start: 3_032,
    h_sync_end: 3_064,
    h_total: 3_600,
    v_active: 2_000,
    v_sync_start: 2_003,
    v_sync_end: 2_008,
    v_total: 2_046,
    h_sync_polarity: 0,
    v_sync_polarity: 1,
    interlaced: 1
  }
  ```
  """
  @spec parse(binary()) :: t() | no_return()
  def parse(modeline_str)

  def parse(modeline_str) when is_binary(modeline_str) do
    [
      clock_str,
      h_active_str,
      h_sync_start_str,
      h_sync_end_str,
      h_total_str,
      v_active_str,
      v_sync_start_str,
      v_sync_end_str,
      v_total_str
      | flags
    ] =
      String.split(modeline_str, ~r/\s+/, trim: true)

    clock = parse_clock(clock_str)

    h_active = parse_active_pixels(h_active_str)
    h_total = parse_total(h_total_str, h_active)
    h_sync_start = parse_sync_start(h_sync_start_str, h_active, h_total)
    h_sync_end = parse_sync_end(h_sync_end_str, h_sync_start, h_total)
    h_sync_polarity = parse_sync_polarity(:horizontal, flags)

    v_active = parse_active_pixels(v_active_str)
    v_total = parse_total(v_total_str, v_active)
    v_sync_start = parse_sync_start(v_sync_start_str, v_active, v_total)
    v_sync_end = parse_sync_end(v_sync_end_str, v_sync_start, v_total)
    v_sync_polarity = parse_sync_polarity(:vertical, flags)

    interlaced = parse_interlaced(flags)

    %__MODULE__{
      clock: clock,
      h_active: h_active,
      h_sync_start: h_sync_start,
      h_sync_end: h_sync_end,
      h_sync_polarity: h_sync_polarity,
      h_total: h_total,
      v_active: v_active,
      v_sync_start: v_sync_start,
      v_sync_end: v_sync_end,
      v_sync_polarity: v_sync_polarity,
      v_total: v_total,
      interlaced: interlaced
    }
  rescue
    e in ArgumentError ->
      message = "Invalid modeline format: #{modeline_str} - #{e.message}"
      reraise ArgumentError, message, __STACKTRACE__

    _ in MatchError ->
      message = "Invalid modeline format: #{modeline_str}"
      reraise ArgumentError, message, __STACKTRACE__
  end

  @spec parse_clock(binary()) :: pos_integer()
  defp parse_clock(str)

  defp parse_clock(str) when is_binary(str) do
    case String.to_float(str) do
      clock when 0.0 < clock and clock <= 655.35 -> round(clock * 1000)
      _ -> raise ArgumentError, message: "Wrong clock value: #{str}"
    end
  end

  @spec parse_active_pixels(binary()) :: pos_integer()
  defp parse_active_pixels(str)

  defp parse_active_pixels(str) when is_binary(str) do
    case String.to_integer(str) do
      active when 1 <= active and active <= 4095 -> active
      _ -> raise ArgumentError, message: "Wrong active pixels value: #{str}"
    end
  end

  @spec parse_total(binary(), pos_integer()) :: pos_integer()
  defp parse_total(str, active_pixels)

  defp parse_total(str, active_pixels)
       when is_binary(str) and is_integer(active_pixels) do
    with total <- String.to_integer(str),
         true <- active_pixels < total and total <= 8191 do
      total
    else
      _ ->
        raise ArgumentError, message: "Wrong total value: #{str}"
    end
  end

  @spec parse_sync_start(binary(), pos_integer(), pos_integer()) :: pos_integer()
  defp parse_sync_start(str, active_pixels, total)

  defp parse_sync_start(str, active_pixels, total)
       when is_binary(str) and is_integer(active_pixels) and is_integer(total) do
    with sync_start <- String.to_integer(str),
         true <- active_pixels < sync_start and sync_start <= total do
      sync_start
    else
      _ ->
        raise ArgumentError, message: "Wrong sync start value: #{str}"
    end
  end

  @spec parse_sync_end(binary(), pos_integer(), pos_integer()) :: pos_integer()
  defp parse_sync_end(str, sync_start, total)

  defp parse_sync_end(str, sync_start, total)
       when is_binary(str) and is_integer(sync_start) and is_integer(total) do
    with sync_end <- String.to_integer(str),
         true <- sync_start < sync_end and sync_end <= total do
      sync_end
    else
      _ ->
        raise ArgumentError, message: "Wrong sync end value: #{str}"
    end
  end

  @spec parse_sync_polarity(:horizontal | :vertical, [binary()]) :: non_neg_integer()
  defp parse_sync_polarity(type, flags)

  defp parse_sync_polarity(type, flags)
       when type in [:horizontal, :vertical] and is_list(flags) do
    flag =
      case type do
        :horizontal -> "-hsync"
        :vertical -> "-vsync"
      end

    flags
    |> Stream.map(&String.downcase/1)
    |> Enum.filter(&(flag == &1))
    |> case do
      [] -> 1
      _ -> 0
    end
  end

  @spec parse_interlaced([binary()]) :: non_neg_integer()
  defp parse_interlaced(flags)

  defp parse_interlaced(flags) when is_list(flags) do
    flags
    |> Stream.map(&String.downcase/1)
    |> Enum.filter(&("interlace" == &1))
    |> case do
      [] -> 0
      _ -> 1
    end
  end
end
