defmodule Edid.CLI do
  @moduledoc """
  This module implements the CLI utility entrypoint.
  """
  use Application

  @impl true
  def start(_, _args) do
    if System.get_env("__BURRITO") == "1" do
      start_cli()
    else
      children = []
      opts = [strategy: :one_for_one, name: Edid.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end

  @doc false
  @spec start_cli() :: no_return()
  def start_cli do
    case Burrito.Util.Args.get_arguments() do
      [spec, filename] ->
        IO.puts("✨ Generating EDID file...")
        Edid.generate(filename, spec)
        IO.puts("✅ EDID file generated successfully: #{filename}")
        System.halt(0)

      [] ->
        print_help()
        System.halt(0)

      _ ->
        print_help()
        System.halt(1)
    end
  rescue
    e in ArgumentError ->
      IO.write(:stderr, e.message)
      print_help()
      System.halt(1)
  end

  @doc false
  @spec print_help() :: :ok
  @spec print_help(nil | binary()) :: :ok
  def print_help(bin_path \\ nil) do
    bin_path = bin_path || Burrito.Util.Args.get_bin_path()

    IO.puts("🎬 EDID Generator CLI")
    IO.puts("====================")
    IO.puts("")
    IO.puts("Usage: #{bin_path} <spec> <filename>")
    IO.puts("")
    IO.puts("Arguments:")
    IO.puts("  📝 spec      - Resolution specifications (comma-separated)")
    IO.puts("               Format: WIDTHxHEIGHT@REFRESH_RATE (e.g., 1920x1080@60)")

    IO.puts(
      "               Or: modeline string (e.g., 148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync)"
    )

    IO.puts("               🎯 Supports mixing resolutions and modelines")
    IO.puts("  📁 filename  - Output EDID file path (.bin extension recommended)")
    IO.puts("")
    IO.puts("Examples:")
    IO.puts("  #{bin_path} 1920x1080@60,2560x1440@90 edid.bin")

    IO.puts(
      "  #{bin_path} '148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync' edid.bin"
    )

    IO.puts("")
    IO.puts("Output:")
    IO.puts("  ✅ EDID file generated successfully")
    IO.puts("  ❌ Error occurred (exit code: 1)")
    IO.puts("")

    :ok
  end
end
