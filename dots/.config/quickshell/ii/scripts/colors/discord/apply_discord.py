import colorsys
from os.path import expanduser, exists
import json
import re

HOME = expanduser("~")
MATERIAL_DISCORD_CSS = HOME + "/.config/BetterDiscord/themes/Material-Discord.theme.css"


def update_hsl(css, property_name, new_value):
    pattern = rf"(--{property_name}:\s*)([^;]+);"
    # Use \g<1> to explicitly reference group 1
    replacement = rf"\g<1>{new_value};"
    return re.sub(pattern, replacement, css)


with open(HOME + "/.local/state/quickshell/user/generated/colors.json", "r") as f:
    COLORS = json.load(f)
    hex = str(COLORS["primary"]).lstrip("#")
    rgb = tuple(int(hex[i : i + 2], 16) for i in (0, 2, 4))
    normalized_rgb = tuple(c / 255.0 for c in rgb)
    hls = colorsys.rgb_to_hls(*normalized_rgb)
    print(rgb)
    print(normalized_rgb)
    print(hls)
    print(str(int(hls[1] * 100)))

if exists(MATERIAL_DISCORD_CSS):
    # 1. Read the existing content
    with open(MATERIAL_DISCORD_CSS, "r") as f:
        css_content = f.read()

    # 2. Perform your updates
    css_content = update_hsl(css_content, "accent-hue", str(int(hls[0] * 360)))
    css_content = update_hsl(
        css_content, "accent-saturation", str(int(hls[1] * 100)) + "%"
    )
    css_content = update_hsl(
        css_content, "accent-lightness", str(int(hls[2] * 100)) + "%"
    )

    # 3. Overwrite the file with the new content
    with open(MATERIAL_DISCORD_CSS, "w") as f:
        f.write(css_content)
