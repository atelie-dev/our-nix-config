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

  # Enables CUDA support, and add extra caches for CUDA packages
  nixpkgs.config.cudaSupport = true;
  nix.settings.extra-substituters = [
    "https://cuda-maintainers.cachix.org"
    "https://cache.nixos-cuda.org"
  ];

  # Temporary workaround for https://github.com/NixOS/nixpkgs/pull/545542
  # CMake 4.3.4 requires bin/nvcc to be inside CUDAToolkit_ROOT, but the CUDA
  # setup hook only collected host-side deps and missed nvcc (in
  # nativeBuildInputs). Override the hook to append nvcc's directory so
  # FindCUDAToolkit can locate it. Remove this overlay once the PR is in our
  # nixpkgs pin.
  nixpkgs.overlays = [
    (_final: prev: {
      cudaPackages = prev.cudaPackages.overrideScope (newFinal: _newPrev: {
        setupCudaHook = newFinal.callPackage (
          {
            lib,
            makeSetupHook,
            backendStdenv,
          }:
          makeSetupHook {
            name = "setup-cuda-hook";
            substitutions.setupCudaHook = placeholder "out";
            substitutions.ccFullPath = "${backendStdenv.cc}/bin/${backendStdenv.cc.targetPrefix}c++";
            meta.license = lib.licenses.mit;
          }
          ./setup-cuda-hook-patched.sh
        ) { };
      });
      # Workaround for onnxruntime v1.27.1 upstream bug: sharded_moe.h
      # references a relocated ft_moe/moe_kernel.h that doesn't exist in the
      # release tarball. Disable CUDA for onnxruntime so firefox (which uses
      # it for translation) falls back to CPU.
      onnxruntime = prev.onnxruntime.override { cudaSupport = false; };
    })
  ];

  # Enables local LLMs
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
