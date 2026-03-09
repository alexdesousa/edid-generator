# EDID Generator

> "Forty-two," said Deep Thought, with infinite majesty and calm.

This tool generates EDID binary files that combine multiple display resolutions.
It's designed for virtual display setups like Sunshine/Moonlight streaming where
you need a single EDID file supporting multiple client resolutions.

## Features

- ✨ Parsing of Xorg modelines with timing parameter extraction
- 🎯 DTD (Detailed Timing Descriptor) generation for each resolution
- 🔄 Support for mixing resolution specs and modeline strings in the same EDID file
- 📦 Support for up to 1028 resolutions (4 standard DTDs + 256 extension blocks × 4 DTDs each)
- 🚀 Fast CLI utility for easy integration

## Usage

```bash
edid_cli <spec> <filename>
```

### Arguments

- 📝 **spec** - Resolution specifications (comma-separated)
  - Format: `WIDTHxHEIGHT@REFRESH_RATE` (e.g., `1920x1080@60`)
  - Or: modeline string (e.g., `148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync`)
  - Or: modeline with Interlace flag (e.g., `441.94 3000 3032 3064 3600 2000 2003 2008 2046 -HSync +VSync Interlace`)
  - 🎯 Supports mixing resolutions and modelines
- 📁 **filename** - Output EDID file path (.bin extension recommended)

### Examples

Generate EDID with multiple resolutions:

```bash
edid_cli 1920x1080@60,2560x1440@90 edid.bin
```

Generate EDID with a modeline string:

```bash
edid_cli '148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync' edid.bin
```

Generate EDID mixing resolution specs and modelines:

```bash
edid_cli '1920x1080@60, 148.50 1920 2008 2052 2200 1080 1083 1088 1125 -HSync +VSync' edid.bin
```

### Pre-built Releases

Download the latest release for your platform from the [releases page](https://github.com/alexdesousa/edid/releases).

### Building from Source

First we need to install the dependencies:

```bash
asdf install
```

> **Note**: The previous command requires you have [ASDF](https://asdf-vm.com/) installed.

And then we can build the CLI utility:

```bash
# Production build
MIX_ENV=prod mix release edid_cli # Builds all binaries
MIX_ENV=prod mix release edid_cli_linux # Build for Linux x86_64
MIX_ENV=prod mix release edid_cli_linux_arm # Build for Linux ARM
MIX_ENV=prod mix release edid_cli_macos # Build for MacOS Intel
MIX_ENV=prod mix release edid_cli_macos_arm # Build for MacOS ARM
MIX_ENV=prod mix release edid_cli_windows # Build for Windows x86_64
```

The release binaries will be located in the folder `./burrito_out/`. If you
want to build the development binaries, remove the `MIX_ENV=prod` environment
variable from the command.

> **Note**: If you want to validate the output, use `edid-decode` Linux command
> to verify the generated EDID file.
>
> ```bash
> edid-decode edid.bin
> ```

## Why?

I use [Sunshine](https://github.com/LizardByte/Sunshine) server on my AI server
to stream video games to my laptop (Linux). My server doesn't have an actual
display, so I tricked the OS by making it believe it had a Microsoft Surface Book
screen attached to it.

> **Note**: I downloaded Microsoft Surface Book EDID file from [v4l-utils](https://git.linuxtv.org/v4l-utils.git/tree/utils/edid-decode/data).
> The reason I picked this specific file is because it was the only one that
> matched the 3:2 resolution of my laptop's screen.

So, I roughly followed the steps in [this blog post](https://www.azdanov.dev/articles/2025/how-to-create-a-virtual-display-for-sunshine-on-arch-linux):

1. First, I added the `microsoft-surfacebook` EDID file I downloaded to `/usr/lib/firmware/edid/`.
2. Then, I added the following line to my `/etc/default/grub`:
   ```bash
   # For identifying the connector, run the following and pick one of them:
   # $ for p in /sys/class/drm/*/status; do con=${p%/status}; echo -n "${con#*/card?-}: "; cat $p; done
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash drm.edid_firmware=HDMI-A-1:edid/microsoft-surfacebook video=HDMI-A-1:e"
   ```
3. And finally, I updated the grub by running `update-grub` and restarted my
   machine.

All was good and I could play from my laptop...

Until I decided to play from my Android tablet. My laptop's resolution didn't
match my tablet's. The video game streaming worked, but it had two ugly black
bands on the sides of the streamed image.

So, after battling in vain, I got an idea: **what if I create a virtual screen that
supports all my desired resolutions—even if it's physically impossible to do so?**

And this project was born!

## Contributing

Contributions, issues, and feature requests are welcome!

## Author

Alex de Sousa.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file
for details.

## Show your support

Give a ⭐️ if you like this project!
