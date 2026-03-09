defmodule Edid.MixProject do
  use Mix.Project

  @version "0.1.0"
  @name "Edid Generator CLI"
  @app :edid

  def project do
    [
      name: @name,
      app: @app,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Edid.CLI, []},
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ]
    ]
  end

  def releases do
    [
      edid_cli: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64],
            linux_arm: [os: :linux, cpu: :aarch64],
            macos: [os: :darwin, cpu: :x86_64],
            macos_arm: [os: :darwin, cpu: :aarch64],
            windows: [os: :windows, cpu: :x86_64]
          ],
          debug: Mix.env() != :prod
        ]
      ],
      edid_cli_linux: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64]
          ],
          debug: Mix.env() != :prod
        ]
      ],
      edid_cli_linux_arm: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux_arm: [os: :linux, cpu: :aarch64]
          ],
          debug: Mix.env() != :prod
        ]
      ],
      edid_cli_macos: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos: [os: :darwin, cpu: :x86_64]
          ],
          debug: Mix.env() != :prod
        ]
      ],
      edid_cli_macos_arm: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos_arm: [os: :darwin, cpu: :aarch64]
          ],
          debug: Mix.env() != :prod
        ]
      ],
      edid_cli_windows: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            windows: [os: :windows, cpu: :x86_64]
          ],
          debug: Mix.env() != :prod
        ]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:burrito, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test, runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/#{@app}.plt"}
    ]
  end
end
