defmodule Edid.Utils do
  @moduledoc """
  This module defines common utilities used in other modules.
  """

  @doc """
  Calculates the checksum of a 127 bytes block.
  """
  @spec checksum(binary()) :: non_neg_integer()
  def checksum(data)

  def checksum(data) when byte_size(data) == 127 do
    data
    |> :binary.bin_to_list()
    |> Enum.sum()
    |> rem(256)
    |> Kernel.-(256)
    |> abs()
  end
end
