defmodule Edid.CLI.Test do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Edid.CLI

  describe inspect(&CLI.print_help/1) do
    test "displays usage information" do
      output = capture_io(fn -> CLI.print_help("edid_cli") end)

      assert output =~ "Usage: edid_cli <spec> <filename>"
      assert output =~ "Arguments:"
      assert output =~ "spec"
      assert output =~ "filename"
      assert output =~ "Examples:"
      assert output =~ "1920x1080@60,2560x1440@90"
      assert output =~ "mixing resolutions and modelines"
    end

    test "includes resolution format examples" do
      output = capture_io(fn -> CLI.print_help("edid_cli") end)

      assert output =~ "WIDTHxHEIGHT@REFRESH_RATE"
      assert output =~ "1920x1080@60"
    end

    test "includes modeline format examples" do
      output = capture_io(fn -> CLI.print_help("edid_cli") end)

      assert output =~ "modeline string"
      assert output =~ "148.50 1920 2008 2052 2200 1080 1083 1088 1125"
    end
  end
end
