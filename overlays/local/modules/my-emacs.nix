{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.emacs;

  myEmacsConfig = pkgs.writeText "config.el" (builtins.readFile ./emacs-files/base.el);
  myEmacsInit = pkgs.writeText "init.el" ''
    ;;; emacs.el -- starts here
    ;;; Commentary:
    ;;; Code:

    ;; Increase the threshold to reduce the amount of garbage collections made
    ;; during startups.
    (let ((gc-cons-threshold (* 50 1000 1000))
          (gc-cons-percentage 0.6)
          (file-name-handler-alist nil))

      ;; Load config
      (load-file "${myEmacsConfig}"))
    ;;; emacs.el ends here
  '';

in {
  options = {
    my.emacs = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enables emacs with the modules I want.
        '';
      };
      enableExwm = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    services.emacs.enable = true;
    services.emacs.package = (import ./emacs-files/elisp.nix { inherit pkgs; }).fromEmacsUsePackage {
      # config = builtins.readFile myEmacsInit; # TODO: Why doesn't this work?
      config = builtins.readFile ./emacs-files/base.el;
      override = epkgs: epkgs // {
        myConfigInit = (pkgs.runCommand "default.el" {} ''
          mkdir -p  $out/share/emacs/site-lisp
          cp ${myEmacsInit} $out/share/emacs/site-lisp/default.el
        '');
      };
      extraEmacsPackages = [ "myConfigInit" ] ++ optionals cfg.enableExwm [ "exwm" "desktop-environment" ];
    };
    services.emacs.defaultEditor = true;

    fonts.fonts = with pkgs; [
      emacs-all-the-icons-fonts
    ];
  };
}
