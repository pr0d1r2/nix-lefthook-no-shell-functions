{
  description = "Lefthook-compatible shell function detector packaged as a Nix flake";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    # Keep the consumer on the pre-actionlint-fragment API.  The newer helper
    # passes a scalar workflow regex to sourceByRegex, whose current nixpkgs
    # implementation requires a list; that breaks flake evaluation before any
    # repository check runs.
    set-and-setting.url = "github:pr0d1r2/set-and-setting/0a5b85c";
    set-and-setting.inputs.nixpkgs-lock.follows = "nixpkgs-lock";
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      ...
    }:
    set-and-setting.lib.mkConsumerFlake {
      inherit self nixpkgs set-and-setting;
      fragments = [
        "base"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
      extraPackages =
        pkgs:
        (
          { bats, wrapper }:
          {
            inherit bats;
            default = pkgs.symlinkJoin {
              name = "lefthook-no-shell-functions";
              paths = [
                bats
                wrapper
              ];
            };
          }
        )
          {
            bats = pkgs.bats.withLibraries (p: [
              p.bats-support
              p.bats-assert
              p.bats-file
            ]);
            wrapper = pkgs.writeShellApplication {
              name = "lefthook-no-shell-functions";
              text = builtins.readFile ./lefthook-no-shell-functions.sh;
            };
          };
      src = ./.;
    };
}
