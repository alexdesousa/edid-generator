defmodule Edid.Resolution do
  @moduledoc """
  This module defines functions to handle resolutions in the format
  `WIDTHxHEIGHT@REFRESH_RATE` and generates structs with said information.

  ## Examples

      iex> Edid.Resolution.parse("1920x1080@60")
      %Edid.Resolution{
        width: 1920,
        height: 1080,
        refresh: 60.0
      }
  """

  @typedoc """
  Resolution.
  """
  @type t :: %__MODULE__{
          width: width :: pos_integer(),
          height: height :: pos_integer(),
          refresh: refresh :: float()
        }

  @doc """
  Resolution config.
  """
  defstruct [
    :width,
    :height,
    :refresh
  ]

  @doc """
  Parses a resolution specification string.

  ## Parameters

  - `spec` - Resolution spec in format `WIDTHxHEIGHT@REFRESH_RATE`

  ## Returns

  `Edid.Resolution.t()` struct with calculated timing parameters

  ## Raises

  - `ArgumentError` - If spec format is invalid

  ## Examples

      iex> Edid.Resolution.parse("1920x1080@60")
      %Edid.Resolution{width: 1920, height: 1080, refresh: 60.0}

      iex> Edid.Resolution.parse("3840x2160@120")
      %Edid.Resolution{width: 3840, height: 2160, refresh: 120.0}

  """
  @spec parse(binary()) :: t()
  def parse(spec)

  def parse(resolution_str) when is_binary(resolution_str) do
    [width_str, height_str, refresh_str] =
      Regex.run(~r/^(\d+)x(\d+)@(\d+(?:\.\d+)?)$/, resolution_str, capture: :all_but_first)

    width = parse_width(width_str)
    height = parse_height(height_str)
    refresh = parse_refresh(refresh_str)

    %__MODULE__{
      width: width,
      height: height,
      refresh: refresh
    }
  rescue
    e in ArgumentError ->
      message = "Invalid resolution format: #{resolution_str} - #{e.message}"
      reraise ArgumentError, message, __STACKTRACE__

    _ in MatchError ->
      message =
        "Invalid resolution format: #{resolution_str}. Expected format: WIDTHxHEIGHT@REFRESH_RATE"

      reraise ArgumentError, message, __STACKTRACE__
  end

  @spec parse_width(binary()) :: pos_integer()
  defp parse_width(str)

  defp parse_width(str) when is_binary(str) do
    case String.to_integer(str) do
      width when 0 < width -> width
      _ -> raise ArgumentError, message: "Wrong width value: #{str}"
    end
  end

  @spec parse_height(binary()) :: pos_integer()
  defp parse_height(str)

  defp parse_height(str) when is_binary(str) do
    case String.to_integer(str) do
      height when 0 < height -> height
      _ -> raise ArgumentError, message: "Wrong height value: #{str}"
    end
  end

  @spec parse_refresh(binary()) :: float()
  defp parse_refresh(str)

  defp parse_refresh(str) when is_binary(str) do
    case Float.parse(str) do
      {refresh, ""} when 0.0 < refresh -> refresh
      _ -> raise ArgumentError, message: "Wrong refresh value: #{str}"
    end
  end
end
