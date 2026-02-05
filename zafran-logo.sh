#!/bin/bash

# Zafran Animated Logo
# Red and White color scheme

# Colors
RED='\033[0;31m'
BRIGHT_RED='\033[1;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# Hide cursor
tput civis

# Cleanup on exit
trap 'tput cnorm; echo -e "${NC}"; exit' INT TERM

# Clear screen
clear

# Get terminal dimensions
COLS=$(tput cols)
LINES=$(tput lines)

# Zafran ASCII Art Frames
declare -a LOGO_FRAMES

LOGO_FRAMES[0]='
    ███████╗
    ╚══███╔╝
      ███╔╝
     ███╔╝
    ███████╗
    ╚══════╝
'

LOGO_FRAMES[1]='
    ███████╗ █████╗
    ╚══███╔╝██╔══██╗
      ███╔╝ ███████║
     ███╔╝  ██╔══██║
    ███████╗██║  ██║
    ╚══════╝╚═╝  ╚═╝
'

LOGO_FRAMES[2]='
    ███████╗ █████╗ ███████╗
    ╚══███╔╝██╔══██╗██╔════╝
      ███╔╝ ███████║█████╗
     ███╔╝  ██╔══██║██╔══╝
    ███████╗██║  ██║██║
    ╚══════╝╚═╝  ╚═╝╚═╝
'

LOGO_FRAMES[3]='
    ███████╗ █████╗ ███████╗██████╗
    ╚══███╔╝██╔══██╗██╔════╝██╔══██╗
      ███╔╝ ███████║█████╗  ██████╔╝
     ███╔╝  ██╔══██║██╔══╝  ██╔══██╗
    ███████╗██║  ██║██║     ██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝
'

LOGO_FRAMES[4]='
    ███████╗ █████╗ ███████╗██████╗  █████╗
    ╚══███╔╝██╔══██╗██╔════╝██╔══██╗██╔══██╗
      ███╔╝ ███████║█████╗  ██████╔╝███████║
     ███╔╝  ██╔══██║██╔══╝  ██╔══██╗██╔══██║
    ███████╗██║  ██║██║     ██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝
'

LOGO_FRAMES[5]='
    ███████╗ █████╗ ███████╗██████╗  █████╗ ███╗   ██╗
    ╚══███╔╝██╔══██╗██╔════╝██╔══██╗██╔══██╗████╗  ██║
      ███╔╝ ███████║█████╗  ██████╔╝███████║██╔██╗ ██║
     ███╔╝  ██╔══██║██╔══╝  ██╔══██╗██╔══██║██║╚██╗██║
    ███████╗██║  ██║██║     ██║  ██║██║  ██║██║ ╚████║
    ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
'

# Full logo for final display
FULL_LOGO='
    ███████╗ █████╗ ███████╗██████╗  █████╗ ███╗   ██╗
    ╚══███╔╝██╔══██╗██╔════╝██╔══██╗██╔══██╗████╗  ██║
      ███╔╝ ███████║█████╗  ██████╔╝███████║██╔██╗ ██║
     ███╔╝  ██╔══██║██╔══╝  ██╔══██╗██╔══██║██║╚██╗██║
    ███████╗██║  ██║██║     ██║  ██║██║  ██║██║ ╚████║
    ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
'

# Function to center text
center_text() {
    local text="$1"
    local width=$(echo "$text" | head -1 | sed 's/\x1b\[[0-9;]*m//g' | wc -c)
    local padding=$(( (COLS - width) / 2 ))
    [ $padding -lt 0 ] && padding=0
    printf "%${padding}s"
}

# Function to display frame
display_frame() {
    local frame="$1"
    local color="$2"
    local start_row=$(( (LINES - 10) / 2 ))

    tput cup $start_row 0

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        center_text "$line"
        echo -e "${color}${line}${NC}"
    done <<< "$frame"
}

# Animation: Letter by letter reveal
animate_reveal() {
    for i in {0..5}; do
        clear
        display_frame "${LOGO_FRAMES[$i]}" "${BRIGHT_RED}"
        sleep 0.15
    done
}

# Animation: Pulse effect
animate_pulse() {
    local colors=("${RED}" "${BRIGHT_RED}" "${WHITE}" "${BRIGHT_RED}" "${RED}")

    for color in "${colors[@]}"; do
        clear
        display_frame "$FULL_LOGO" "$color"
        sleep 0.12
    done
}

# Animation: Glitch effect
animate_glitch() {
    local glitch_chars=('█' '▓' '▒' '░' ' ')

    for _ in {1..3}; do
        clear
        local start_row=$(( (LINES - 10) / 2 ))
        tput cup $start_row 0

        while IFS= read -r line; do
            [ -z "$line" ] && continue
            center_text "$line"

            # Random glitch
            local glitched=""
            for (( i=0; i<${#line}; i++ )); do
                char="${line:$i:1}"
                if [ $((RANDOM % 10)) -lt 2 ]; then
                    glitched+="${glitch_chars[$((RANDOM % 5))]}"
                else
                    glitched+="$char"
                fi
            done
            echo -e "${BRIGHT_RED}${glitched}${NC}"
        done <<< "$FULL_LOGO"
        sleep 0.05
    done
}

# Animation: Scan line effect
animate_scanline() {
    local logo_lines=()
    while IFS= read -r line; do
        [ -n "$line" ] && logo_lines+=("$line")
    done <<< "$FULL_LOGO"

    local start_row=$(( (LINES - 10) / 2 ))

    for scan in {0..6}; do
        clear
        tput cup $start_row 0

        for i in "${!logo_lines[@]}"; do
            center_text "${logo_lines[$i]}"
            if [ $i -eq $scan ]; then
                echo -e "${WHITE}${logo_lines[$i]}${NC}"
            else
                echo -e "${RED}${logo_lines[$i]}${NC}"
            fi
        done
        sleep 0.08
    done
}

# Tagline animation
animate_tagline() {
    local tagline="Security Threat Exposure Management"
    local start_row=$(( (LINES - 10) / 2 + 8 ))

    # Calculate center position
    local padding=$(( (COLS - ${#tagline}) / 2 ))

    # Type out effect
    tput cup $start_row 0
    printf "%${padding}s" ""

    for (( i=0; i<${#tagline}; i++ )); do
        echo -n -e "${WHITE}${tagline:$i:1}${NC}"
        sleep 0.03
    done
}

# Particle effect around logo
animate_particles() {
    local particles=('·' '•' '◦' '○' '◎' '●')
    local start_row=$(( (LINES - 10) / 2 - 2 ))
    local logo_width=58
    local logo_start=$(( (COLS - logo_width) / 2 ))

    for _ in {1..15}; do
        # Random position around logo
        local px=$((logo_start + RANDOM % logo_width))
        local py=$((start_row + RANDOM % 12))
        local particle="${particles[$((RANDOM % 6))]}"

        tput cup $py $px
        echo -n -e "${RED}${particle}${NC}"
        sleep 0.02
    done
}

# Final static display with glow effect
final_display() {
    clear

    # Add decorative border
    local start_row=$(( (LINES - 14) / 2 ))
    local border_width=70
    local border_start=$(( (COLS - border_width) / 2 ))

    # Top border
    tput cup $start_row $border_start
    echo -n -e "${RED}"
    printf '╔'
    printf '═%.0s' $(seq 1 $((border_width - 2)))
    printf '╗'
    echo -e "${NC}"

    # Logo with side borders
    local row=$((start_row + 1))
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        tput cup $row $border_start
        echo -n -e "${RED}║${NC}"

        local line_clean=$(echo "$line" | sed 's/^    //')
        local inner_padding=$(( (border_width - ${#line_clean} - 2) / 2 ))

        printf "%${inner_padding}s" ""
        echo -n -e "${BRIGHT_RED}${line_clean}${NC}"
        printf "%${inner_padding}s" ""

        tput cup $row $((border_start + border_width - 1))
        echo -e "${RED}║${NC}"
        ((row++))
    done <<< "$FULL_LOGO"

    # Tagline
    tput cup $row $border_start
    echo -n -e "${RED}║${NC}"
    local tagline="Security Threat Exposure Management"
    local tag_padding=$(( (border_width - ${#tagline} - 2) / 2 ))
    printf "%${tag_padding}s" ""
    echo -n -e "${WHITE}${tagline}${NC}"
    printf "%${tag_padding}s" ""
    tput cup $row $((border_start + border_width - 1))
    echo -e "${RED}║${NC}"
    ((row++))

    # Bottom border
    tput cup $row $border_start
    echo -n -e "${RED}"
    printf '╚'
    printf '═%.0s' $(seq 1 $((border_width - 2)))
    printf '╝'
    echo -e "${NC}"

    # Version info
    ((row += 2))
    local version="Prompt Improver v1.0.0"
    local ver_padding=$(( (COLS - ${#version}) / 2 ))
    tput cup $row 0
    printf "%${ver_padding}s" ""
    echo -e "${GRAY}${version}${NC}"
}

# Main animation sequence
main() {
    # Initial reveal
    animate_reveal
    sleep 0.2

    # Glitch effect
    animate_glitch
    sleep 0.1

    # Pulse effect
    animate_pulse
    animate_pulse
    sleep 0.1

    # Scan line
    animate_scanline
    sleep 0.1

    # Final display
    final_display

    # Add particles
    animate_particles
    sleep 0.5

    # Show cursor and wait
    tput cnorm
    echo ""
    echo ""

    # Wait for keypress or timeout
    read -t 3 -n 1 -s 2>/dev/null || true
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
