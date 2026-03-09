defmodule Edid.BlankingTest do
  use ExUnit.Case, async: true
  doctest Edid.Blanking

  alias Edid.Blanking
  alias Edid.Modeline

  describe inspect(&Blanking.calculate/1) do
    test "should calculate blanking parameters correctly" do
      modeline_str = "441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +Vsync"
      modeline = Modeline.parse(modeline_str)

      assert %Blanking{} = blanking = Blanking.calculate(modeline)

      assert blanking.h_blanking == 600
      assert blanking.v_blanking == 46
      assert blanking.h_offset == 32
      assert blanking.v_offset == 3
      assert blanking.h_pulse == 32
      assert blanking.v_pulse == 5
    end
  end
end
