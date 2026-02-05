#!/bin/bash

# Zafran Static Logo - Fast display version
# Red and White color scheme

# Colors
RED='\033[0;31m'
BRIGHT_RED='\033[1;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

display_logo() {
    clear
    echo ""
    echo ""
    echo -e "${BRIGHT_RED}    ███████╗ █████╗ ███████╗██████╗  █████╗ ███╗   ██╗${NC}"
    echo -e "${BRIGHT_RED}    ╚══███╔╝██╔══██╗██╔════╝██╔══██╗██╔══██╗████╗  ██║${NC}"
    echo -e "${RED}      ███╔╝ ███████║█████╗  ██████╔╝███████║██╔██╗ ██║${NC}"
    echo -e "${RED}     ███╔╝  ██╔══██║██╔══╝  ██╔══██╗██╔══██║██║╚██╗██║${NC}"
    echo -e "${BRIGHT_RED}    ███████╗██║  ██║██║     ██║  ██║██║  ██║██║ ╚████║${NC}"
    echo -e "${BRIGHT_RED}    ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝${NC}"
    echo ""
    echo -e "${WHITE}        Security Threat Exposure Management${NC}"
    echo ""
    echo -e "${GRAY}                  Prompt Improver v1.0.0${NC}"
    echo ""
    sleep 1
}

# Compact version for inline display
display_logo_compact() {
    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BRIGHT_RED}███████╗ █████╗ ███████╗██████╗  █████╗ ███╗   ██╗${NC}   ${RED}║${NC}"
    echo -e "${RED}║${NC}  ${BRIGHT_RED}╚══███╔╝██╔══██╗██╔════╝██╔══██╗██╔══██╗████╗  ██║${NC}   ${RED}║${NC}"
    echo -e "${RED}║${NC}  ${RED}  ███╔╝ ███████║█████╗  ██████╔╝███████║██╔██╗ ██║${NC}   ${RED}║${NC}"
    echo -e "${RED}║${NC}  ${RED} ███╔╝  ██╔══██║██╔══╝  ██╔══██╗██╔══██║██║╚██╗██║${NC}   ${RED}║${NC}"
    echo -e "${RED}║${NC}  ${BRIGHT_RED}███████╗██║  ██║██║     ██║  ██║██║  ██║██║ ╚████║${NC}   ${RED}║${NC}"
    echo -e "${RED}║${NC}  ${BRIGHT_RED}╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝${NC}   ${RED}║${NC}"
    echo -e "${RED}║${NC}                                                           ${RED}║${NC}"
    echo -e "${RED}║${NC}       ${WHITE}Security Threat Exposure Management${NC}              ${RED}║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Mini version
display_logo_mini() {
    echo -e "${BRIGHT_RED}╔════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_RED}║${NC}  ${WHITE}ZAFRAN${NC} ${GRAY}Prompt Improver${NC}          ${BRIGHT_RED}║${NC}"
    echo -e "${BRIGHT_RED}╚════════════════════════════════════╝${NC}"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    display_logo
fi
