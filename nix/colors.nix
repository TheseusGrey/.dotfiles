# colors.nix
let
    none = "NONE";

    black0 = "0x191D24";
    black1 = "0x1E222A";
    black2 = "0x222630";

    gray0 = "0x242933";
    gray1 = "0x2E3440";
    gray2 = "0x3B4252";
    gray3 = "0x434C5E";
    gray4 = "0x4C566A";
    gray5 = "0x60728A";

    white0_normal = "0xBBC3D4";
    white0_reduce_blue = "0xC0C8D8";

    white1 = "0xD8DEE9";
    white2 = "0xE5E9F0";
    white3 = "0xECEFF4";

    blue0 = "0x5E81AC";
    blue1 = "0x81A1C1";
    blue2 = "0x88C0D0";

    cyan = {
        base = "0x8FBCBB";
        bright = "0x9FC6C5";
        dim = "0x80B3B2";
    };

    red = {
        base = "0xBF616A";
        bright = "0xC5727A";
        dim = "0xB74E58";
    };
    orange = {
        base = "0xD08770";
        bright = "0xD79784";
        dim = "0xCB775D";
    };
    yellow = {
        base = "0xEBCB8B";
        bright = "0xEFD49F";
        dim = "0xE7C173";
    };
    green = {
        base = "0xA3BE8C";
        bright = "0xB1C89D";
        dim = "0x97B67C";
    };
    magenta = {
        base = "0xB48EAD";
        bright = "0xBE9DB8";
        dim = "0xA97EA1";
    };
in
{
  # Color blend formula (per RBG channel)
  # (a, b, alpha) => a * alpha + (1 - alpha) * b
  # always round up, clamp to (0, 255) range

  # Background
  bg = gray0;
  bg_light = black1;
  bg_dark = black0;
  bg_verticalbar = gray0;
  bg_popup = gray0;
  bg_horizontalbar = black0;
  bg_selected = "0x272C37"; # Blended gray2 + black0, alpha = 0.4
  bg_fold = gray2;
  bg_float = black1;
  
  # Foreground
  fg = white0_normal;
  fg_light = white1;
  fg_dark = white0_normal;
  fg_verticalbar = white2;
  fg_popup = white0_normal;
  fg_horizontalbar = white0_normal;
  fg_selected = white1;
  fg_fold = white0_normal;
  fg_float = white0_normal;

  # Border
  bg_border = gray0;
  bg_popup_border = gray0;
  bg_float_border = black1;
  fg_border = black0;
  fg_popup_border = black0;
  fg_float_border = black0;

  # Cursor
  cursor = black0;

  # Status
  positive = green.base;
  negative = red.base;
  change = blue0;

  error = red.bright;
  warn = yellow.base;
  hint = green.bright;
  info = blue2;
  
  # Misc
  comment = gray4;
}
