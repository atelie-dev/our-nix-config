# Shared 1Password configuration: desktop app + Environments MCP server support.
#
# The MCP server binary ships inside the 1Password desktop app. The app's MCP
# relay verifies connecting peers via SO_PEERCRED and requires the peer's
# effective GID to be the `onepassword-mcp` group (confirmed by disassembly:
# op_sys_info::process_information::linux::get_mcp_gid looks up that group
# name). Upstream's .deb install script creates the group and installs the
# binary as root:onepassword-mcp mode 2755 (setgid); nixpkgs does neither.
#
# Nix store paths are read-only and root:root, and /run is mounted nosuid, so
# we use a NixOS security.wrappers setgid wrapper (installed under
# /run/wrappers, which is NOT nosuid) with world-executable permissions —
# users don't need group membership, mirroring upstream's 2755 mode.
#
# NOTE: the desktop app resolves the group at connection time via nscd/NSS;
# after changing group setup, fully quit 1Password (tray included) and
# relaunch it.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Grant the polkit policy to every regular user of the machine, so each
    # machine gets the right owner without per-machine overrides.
    polkitPolicyOwners = lib.attrNames (
      lib.filterAttrs (_: user: user.isNormalUser) config.users.users
    );
  };

  # Group required by the app's MCP peer effective-GID check (get_mcp_gid).
  # The relay rejects peers whose egid is < 1000 (system range) or 65534
  # (nogroup) — verified by disassembling verify_connecting_process — so the
  # group needs a fixed GID in the user range, next to the other 1Password
  # groups. Users are deliberately NOT members (upstream guidance): the
  # wrapper is world-executable and the setgid bit supplies the effective GID.
  users.groups."onepassword-mcp" = {
    gid = 31003;
  };

  # Root-owned setgid copy of the MCP binary (upstream's after-install.sh
  # model: chgrp onepassword-mcp + chmod g+s). Lives under /run (nosuid, so
  # its own setgid bit is inert) — the effective GID comes from the wrapper
  # below; the copy exists so the peer's binary file metadata (owner, group,
  # setgid) is exactly what the app's BinaryPermissions check expects.
  systemd.tmpfiles.rules = [
    "C+ /run/1password-mcp/1password-mcp 2755 root onepassword-mcp - ${pkgs._1password-gui}/share/1password/1password-mcp"
  ];

  # Setgid wrapper: /run/wrappers/bin/1password-mcp runs with the
  # `onepassword-mcp` group as effective GID (/run/wrappers is not nosuid)
  # and execs the root:onepassword-mcp setgid copy above, so the final
  # process presents the exact file metadata upstream's install produces.
  # World-executable: users don't need group membership.
  security.wrappers."1password-mcp" = {
    source = "/run/1password-mcp/1password-mcp";
    owner = "root";
    group = "onepassword-mcp";
    setgid = true;
    permissions = "u+rx,g+rx,o+rx";
  };
}
