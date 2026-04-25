# This file contains configuration specific to the NVidia hardware.
# Hopefully we'll replace the GPU to a more open architecture in the future.

{ config, pkgs, ... }:
{
  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # Fix for the GTK4 freeze-on-close bug: https://forums.developer.nvidia.com/t/580-release-feedback-discussion/341205/20
  environment.sessionVariables.GSK_RENDERER = "ngl";

  # Enables local LLMs
  nixpkgs.config.cudaSupport = true;
  services.ollama = {
    enable = true;
    home = "/mnt/magnetic/ollama";
  };

  environment.systemPackages = [
    pkgs.nvtopPackages.nvidia # htop-like task monitor for AMD, Adreno, Intel and NVIDIA GPUs
  ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;
  };
}
