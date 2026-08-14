{ config, pkgs, ... }:
{
  # Enable Logitech udev rules
  hardware.logitech.wireless.enable = true;

  programs.solaar = {
    enable = true;
    userService.enable = true;
    userService.window = "hide";
  };
}
