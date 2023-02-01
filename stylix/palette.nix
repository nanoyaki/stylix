{ palette-generator, base16 }:
{ pkgs, lib, config, ... }@args:

with lib;

let
  fromOs = import ./fromos.nix { inherit lib args; };

  cfg = config.stylix;

  paletteJSON = pkgs.runCommand "palette.json" { } ''
    ${palette-generator}/bin/palette-generator ${cfg.polarity} ${cfg.image} $out
  '';
  generatedPalette = importJSON paletteJSON;

  generatedScheme = generatedPalette // {
    author = "Stylix";
    scheme = "Stylix";
    slug = "stylix";
  };

in {
  options.stylix = {
    polarity = mkOption {
      type = types.enum [ "either" "light" "dark" ];
      default = fromOs [ "polarity" ] "either";
      description = ''
        Use this option to force a light or dark theme.

        By default we will select whichever is ranked better by the genetic
        algorithm. This aims to get good contrast between the foreground and
        background, as well as some variety in the highlight colours.
      '';
    };

    image = mkOption {
      type = types.coercedTo types.package toString types.path;
      description = ''
        Wallpaper image.

        This is set as the background of your desktop environment, if possible,
        and used to generate a colour scheme if you don't set one manually.
      '';
      default = fromOs [ "image" ] null;
    };

    generated = {
      json = mkOption {
        type = types.path;
        description = "The result of palette-generator.";
        readOnly = true;
        internal = true;
        default = paletteJSON;
      };

      palette = mkOption {
        type = types.attrs;
        description = "The imported json";
        readOnly = true;
        internal = true;
        default = generatedPalette;
      };
    };

    # TODO proper removal of palette

    base16Scheme = mkOption {
      description = ''
        A scheme following the base16 standard.

        This can be a path to a file, a string of YAML, or an attribute set.
      '';
      type = with types; oneOf [ path lines attrs ];
      default =
        if args ? "osConfig" && cfg.image != args.osConfig.stylix.image
          then generatedScheme
          else fromOs [ "base16Scheme" ] generatedScheme;
      defaultText = literalDocBook ''
        The colors used in the theming.

        Those are automatically selected from the background image by default,
        but could be overridden manually.
      '';
    };
  };

  config = {
    # This attrset can be used like a function too, see
    # https://github.com/SenchoPens/base16.nix#mktheme
    lib.stylix.colors = base16.mkSchemeAttrs cfg.base16Scheme;
  };
}
