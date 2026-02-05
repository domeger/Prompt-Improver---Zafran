#!/bin/bash

# Prompt Improver - Interactive CLI Tool
# Uses Ollama with gemma3:12b model locally
# Inspired by Claude Code interface

MODEL="gemma3:12b"
OLLAMA_URL="http://localhost:11434/api/generate"
HISTORY_FILE="$HOME/.prompt_improver_history"
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHOW_LOGO="${SHOW_LOGO:-true}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Intent analysis mode (on/off)
INTENT_MODE="on"

# System prompt for improvement
SYSTEM_PROMPT='You are a prompt engineering expert. Transform simple prompts into comprehensive, detailed prompts that generate professional outputs.

Enhancement techniques to apply:

1. **Specificity & Context** - Define scope, target audience, domain context
2. **Structure** - Add sections (Executive Summary, Methodology, Findings, Recommendations)
3. **Data Requirements** - Request breakdowns, metrics, percentages, tables
4. **Risk & Impact** - Include risk assessments, impact analysis
5. **Timeline Actions** - Immediate/short-term/long-term recommendations
6. **Quality Elements** - Data sources, validation, exclusions mentioned
7. **Accountability** - Ownership, KPIs, success metrics
8. **Formatting** - Headers, bullet points, tables, confidentiality labels

IMPORTANT: Output ONLY the improved prompt. No explanations or commentary.'

# System prompt for intent analysis
INTENT_ANALYSIS_PROMPT='You are a prompt analyst. Analyze the user input and determine if it lacks essential information to generate a good output.

Check for these missing elements:
1. **Subject/Topic** - What is the main subject?
2. **Scope** - What boundaries or limits?
3. **Audience** - Who is the target reader?
4. **Purpose** - What is the goal/outcome?
5. **Format** - What type of output is expected?
6. **Context** - Any domain-specific details needed?

If the prompt is CLEAR ENOUGH (has subject + purpose at minimum), respond with:
CLEAR

If the prompt NEEDS CLARIFICATION, respond with EXACTLY this format:
QUESTIONS
1. [First clarifying question]
2. [Second clarifying question]
3. [Third clarifying question if needed]

Rules:
- Maximum 3 questions
- Questions should be short and specific
- Only ask what is truly necessary
- If the prompt has enough context, say CLEAR
- Do not explain, just output CLEAR or QUESTIONS with the list'

# Get terminal dimensions
get_term_width() {
    tput cols 2>/dev/null || echo 80
}

# Draw a horizontal line
draw_line() {
    local char="${1:-─}"
    local color="${2:-$GRAY}"
    local width=$(get_term_width)
    printf "${color}"
    printf '%*s' "$width" '' | tr ' ' "$char"
    printf "${NC}\n"
}

# Draw header box
draw_header() {
    local width=$(get_term_width)
    clear
    echo ""
    printf "${CYAN}╭"
    printf '%*s' "$((width-2))" '' | tr ' ' '─'
    printf "╮${NC}\n"

    local title="Prompt Improver"
    local subtitle="Local LLM · gemma3:12b"
    local padding=$(( (width - ${#title} - 2) / 2 ))

    printf "${CYAN}│${NC}"
    printf '%*s' "$padding" ''
    printf "${BOLD}${YELLOW}%s${NC}" "$title"
    printf '%*s' "$((width - padding - ${#title} - 2))" ''
    printf "${CYAN}│${NC}\n"

    padding=$(( (width - ${#subtitle} - 2) / 2 ))
    printf "${CYAN}│${NC}"
    printf '%*s' "$padding" ''
    printf "${DIM}%s${NC}" "$subtitle"
    printf '%*s' "$((width - padding - ${#subtitle} - 2))" ''
    printf "${CYAN}│${NC}\n"

    printf "${CYAN}╰"
    printf '%*s' "$((width-2))" '' | tr ' ' '─'
    printf "╯${NC}\n"
    echo ""
}

# Show commands help
show_commands() {
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo -e "  ${CYAN}/help${NC}      Show this help"
    echo -e "  ${CYAN}/intent${NC}    Toggle intent analysis (current: $INTENT_MODE)"
    echo -e "  ${CYAN}/model${NC}     Change model (current: $MODEL)"
    echo -e "  ${CYAN}/history${NC}   Show prompt history"
    echo -e "  ${CYAN}/clear${NC}     Clear screen"
    echo -e "  ${CYAN}/save${NC}      Save last output to file"
    echo -e "  ${CYAN}/quit${NC}      Exit the tool"
    echo ""
    echo -e "${DIM}Type any text to improve it as a prompt${NC}"
    echo -e "${DIM}Intent analysis asks clarifying questions for vague prompts${NC}"
    echo ""
}

# Spinner for loading
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${CYAN}%c${NC} ${DIM}Improving with ${MODEL}...${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r\033[K"
    done
    printf "\r\033[K"
}

# Check Ollama
check_ollama() {
    if ! curl -s "http://localhost:11434/api/tags" > /dev/null 2>&1; then
        echo -e "${RED}✗ Ollama is not running${NC}"
        echo -e "${DIM}  Start with: ollama serve${NC}"
        return 1
    fi

    if ! ollama list 2>/dev/null | grep -q "$MODEL"; then
        echo -e "${RED}✗ Model $MODEL not found${NC}"
        echo -e "${DIM}  Pull with: ollama pull $MODEL${NC}"
        return 1
    fi
    return 0
}

# Call LLM helper function
call_llm() {
    local prompt="$1"
    local max_tokens="${2:-1024}"

    local response=$(jq -n \
        --arg model "$MODEL" \
        --arg prompt "$prompt" \
        --argjson max_tokens "$max_tokens" \
        '{
            model: $model,
            prompt: $prompt,
            stream: false,
            options: {
                temperature: 0.7,
                num_predict: $max_tokens
            }
        }' | curl -s "$OLLAMA_URL" \
        -H "Content-Type: application/json" \
        -d @- 2>/dev/null)

    echo "$response" | jq -r '.response // empty'
}

# Analyze intent and ask clarifying questions
analyze_intent() {
    local input_prompt="$1"
    local result_file="$2"

    # Build analysis prompt
    local analysis_prompt="$INTENT_ANALYSIS_PROMPT

---
Analyze this prompt:
$input_prompt
---"

    # Show spinner (to stderr so it doesn't mix with result)
    printf " ${CYAN}⠋${NC} ${DIM}Analyzing prompt...${NC}" >&2

    local tmp_file=$(mktemp)
    (jq -n \
        --arg model "$MODEL" \
        --arg prompt "$analysis_prompt" \
        '{
            model: $model,
            prompt: $prompt,
            stream: false,
            options: {
                temperature: 0.3,
                num_predict: 512
            }
        }' | curl -s "$OLLAMA_URL" \
        -H "Content-Type: application/json" \
        -d @- > "$tmp_file" 2>/dev/null) &

    local pid=$!
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r ${CYAN}%c${NC} ${DIM}Analyzing prompt...${NC}" "$spinstr" >&2
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    wait $pid
    printf "\r\033[K" >&2

    local analysis=$(cat "$tmp_file" | jq -r '.response // empty')
    rm -f "$tmp_file"

    # Check if analysis says CLEAR or has questions
    if echo "$analysis" | grep -q "CLEAR"; then
        echo "CLEAR" > "$result_file"
        return 0
    fi

    # Extract questions
    local questions=$(echo "$analysis" | grep -E "^[0-9]+\." | head -3)

    if [ -z "$questions" ]; then
        echo "CLEAR" > "$result_file"
        return 0
    fi

    echo "$questions" > "$result_file"
}

# Gather clarifications interactively
gather_clarifications() {
    local input_prompt="$1"
    local questions_file="$2"
    local result_file="$3"

    echo ""
    echo -e "${YELLOW}┌─ Clarification Needed ─────────────────────────────${NC}"
    echo -e "${DIM}  Your prompt could be improved with more context.${NC}"
    echo -e "${DIM}  Answer the questions below (or press Enter to skip):${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────${NC}"
    echo ""

    local answers=""
    local i=1

    # Read questions from file using file descriptor 3, keeping stdin free for user input
    exec 3< "$questions_file"

    while IFS= read -r question <&3 || [ -n "$question" ]; do
        [ -z "$question" ] && continue

        # Remove leading number and dot (e.g., "1. " or "2. ")
        local clean_q="${question#[0-9]. }"
        clean_q="${clean_q#[0-9][0-9]. }"
        [ -z "$clean_q" ] && continue

        echo -e "${CYAN}Q$i:${NC} $clean_q"
        printf "${MAGENTA}A$i:${NC} "

        # Read answer from stdin (terminal)
        local answer=""
        read -r answer

        if [ -n "$answer" ]; then
            answers="${answers}
- ${clean_q}: ${answer}"
        fi

        i=$((i + 1))
    done

    exec 3<&-  # Close file descriptor

    # Combine original prompt with answers
    if [ -n "$answers" ]; then
        cat > "$result_file" << EOF
${input_prompt}

Additional context provided:
${answers}
EOF
    else
        echo "$input_prompt" > "$result_file"
    fi
}

# Improve prompt function
improve_prompt() {
    local input_prompt="$1"
    local skip_intent="${2:-false}"

    # Intent analysis (if enabled and not skipped)
    if [ "$INTENT_MODE" = "on" ] && [ "$skip_intent" = "false" ]; then
        local intent_file=$(mktemp)
        local enhanced_file=$(mktemp)

        analyze_intent "$input_prompt" "$intent_file"
        local intent_result=$(cat "$intent_file")

        if [ "$intent_result" != "CLEAR" ] && [ -n "$intent_result" ]; then
            # Has questions - gather clarifications
            gather_clarifications "$input_prompt" "$intent_file" "$enhanced_file"
            input_prompt=$(cat "$enhanced_file")
        else
            echo -e "${GREEN}✓${NC} ${DIM}Prompt is clear, proceeding...${NC}"
        fi

        rm -f "$intent_file" "$enhanced_file"
    fi

    # Show original (possibly enhanced with clarifications)
    echo ""
    echo -e "${GRAY}┌─ Original ──────────────────────────────────────────${NC}"
    echo -e "${WHITE}${input_prompt}${NC}" | fold -s -w $(($(get_term_width) - 4)) | while IFS= read -r line; do echo "  $line"; done
    echo -e "${GRAY}└─────────────────────────────────────────────────────${NC}"
    echo ""

    # Build full prompt
    local full_prompt="$SYSTEM_PROMPT

---
Improve this prompt:
$input_prompt
---

Output ONLY the improved prompt:"

    # Create temp file for response
    local tmp_file=$(mktemp)

    # Call Ollama API in background
    (jq -n \
        --arg model "$MODEL" \
        --arg prompt "$full_prompt" \
        '{
            model: $model,
            prompt: $prompt,
            stream: false,
            options: {
                temperature: 0.7,
                num_predict: 2048
            }
        }' | curl -s "$OLLAMA_URL" \
        -H "Content-Type: application/json" \
        -d @- > "$tmp_file" 2>/dev/null) &

    local curl_pid=$!
    spinner $curl_pid
    wait $curl_pid

    # Read response from temp file
    local response=$(cat "$tmp_file")
    rm -f "$tmp_file"

    local improved=$(echo "$response" | jq -r '.response // empty')

    if [ -z "$improved" ]; then
        echo -e "${RED}✗ Failed to get response${NC}"
        return 1
    fi

    # Store for /save command
    LAST_OUTPUT="$improved"
    LAST_INPUT="$input_prompt"

    # Save to history
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$input_prompt" >> "$HISTORY_FILE"

    # Show improved
    echo -e "${GREEN}┌─ Improved ──────────────────────────────────────────${NC}"
    echo ""
    echo "$improved" | fold -s -w $(($(get_term_width) - 4)) | while IFS= read -r line; do echo "  $line"; done
    echo ""
    echo -e "${GREEN}└─────────────────────────────────────────────────────${NC}"
    echo ""

    # Stats
    local orig_words=$(echo "$input_prompt" | wc -w | tr -d ' ')
    local new_words=$(echo "$improved" | wc -w | tr -d ' ')
    local ratio=$((new_words / orig_words))
    echo -e "${DIM}  Words: $orig_words → $new_words (${ratio}x expansion)${NC}"
    echo ""
}

# Handle commands
handle_command() {
    local cmd="$1"

    case "$cmd" in
        /help|/h)
            show_commands
            ;;
        /intent|/i)
            if [ "$INTENT_MODE" = "on" ]; then
                INTENT_MODE="off"
                echo -e "${YELLOW}✗ Intent analysis: OFF${NC}"
                echo -e "${DIM}  Prompts will be improved directly without clarification${NC}"
            else
                INTENT_MODE="on"
                echo -e "${GREEN}✓ Intent analysis: ON${NC}"
                echo -e "${DIM}  Vague prompts will trigger clarifying questions${NC}"
            fi
            echo ""
            ;;
        /model|/m)
            echo -e "${CYAN}Available models:${NC}"
            ollama list 2>/dev/null | tail -n +2 | awk '{print "  " $1}'
            echo ""
            echo -n -e "${YELLOW}Enter model name: ${NC}"
            read -r new_model
            if [ -n "$new_model" ]; then
                MODEL="$new_model"
                echo -e "${GREEN}✓ Model set to: $MODEL${NC}"
            fi
            ;;
        /history)
            if [ -f "$HISTORY_FILE" ]; then
                echo -e "${CYAN}Recent prompts:${NC}"
                tail -10 "$HISTORY_FILE" | while IFS='|' read -r timestamp prompt; do
                    echo -e "  ${DIM}$timestamp${NC} $prompt"
                done | head -20
            else
                echo -e "${DIM}No history yet${NC}"
            fi
            echo ""
            ;;
        /clear|/c)
            draw_header
            ;;
        /save|/s)
            if [ -n "$LAST_OUTPUT" ]; then
                local filename="improved_prompt_$(date '+%Y%m%d_%H%M%S').txt"
                echo "$LAST_OUTPUT" > "$filename"
                echo -e "${GREEN}✓ Saved to: $filename${NC}"
            else
                echo -e "${DIM}Nothing to save yet${NC}"
            fi
            echo ""
            ;;
        /quit|/q|/exit)
            echo ""
            echo -e "${CYAN}Goodbye!${NC}"
            echo ""
            exit 0
            ;;
        /*)
            echo -e "${RED}Unknown command: $cmd${NC}"
            echo -e "${DIM}Type /help for available commands${NC}"
            echo ""
            ;;
    esac
}

# Show startup logo animation
show_logo_animation() {
    if [ "$SHOW_LOGO" = "true" ] && [ -f "$SCRIPT_DIR/zafran-logo.sh" ]; then
        source "$SCRIPT_DIR/zafran-logo.sh"
        main  # Run the logo animation
        sleep 0.5
    fi
}

# Interactive mode
interactive_mode() {
    # Show logo animation on startup
    show_logo_animation

    draw_header

    if ! check_ollama; then
        exit 1
    fi

    echo -e "${GREEN}✓ Connected to Ollama${NC}"
    if [ "$INTENT_MODE" = "on" ]; then
        echo -e "${GREEN}✓ Intent analysis: ON${NC} ${DIM}(asks clarifying questions for vague prompts)${NC}"
    else
        echo -e "${YELLOW}○ Intent analysis: OFF${NC}"
    fi
    echo ""
    echo -e "${DIM}Type a simple prompt to improve it, or /help for commands${NC}"
    echo ""

    while true; do
        echo -n -e "${MAGENTA}❯${NC} "
        read -r user_input

        # Skip empty input
        [ -z "$user_input" ] && continue

        # Handle commands
        if [[ "$user_input" == /* ]]; then
            handle_command "$user_input"
        else
            improve_prompt "$user_input"
        fi
    done
}

# Non-interactive mode
non_interactive() {
    local input_prompt="$1"
    local output_file="$2"

    if ! check_ollama; then
        exit 1
    fi

    local full_prompt="$SYSTEM_PROMPT

---
Improve this prompt:
$input_prompt
---

Output ONLY the improved prompt:"

    echo -e "${CYAN}Improving prompt...${NC}" >&2

    local response=$(jq -n \
        --arg model "$MODEL" \
        --arg prompt "$full_prompt" \
        '{
            model: $model,
            prompt: $prompt,
            stream: false,
            options: {
                temperature: 0.7,
                num_predict: 2048
            }
        }' | curl -s "$OLLAMA_URL" \
        -H "Content-Type: application/json" \
        -d @- 2>/dev/null)

    local improved=$(echo "$response" | jq -r '.response // empty')

    if [ -z "$improved" ]; then
        echo -e "${RED}Error: Failed to get response${NC}" >&2
        exit 1
    fi

    if [ -n "$output_file" ]; then
        echo "$improved" > "$output_file"
        echo -e "${GREEN}✓ Saved to: $output_file${NC}" >&2
    else
        echo "$improved"
    fi
}

# Show help
show_help() {
    echo ""
    echo -e "${BOLD}Prompt Improver${NC} v$VERSION"
    echo -e "${DIM}Transform simple prompts into comprehensive ones using local LLM${NC}"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo "  $(basename $0)                    # Interactive mode"
    echo "  $(basename $0) \"prompt\"           # Single prompt"
    echo "  $(basename $0) -f file.txt        # From file"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  -h, --help           Show this help"
    echo "  -f, --file FILE      Read prompt from file"
    echo "  -o, --output FILE    Save to file"
    echo "  -m, --model MODEL    Use different model"
    echo "  --no-intent          Disable intent analysis"
    echo ""
    echo -e "${BOLD}Interactive Commands:${NC}"
    echo "  /help    Show commands"
    echo "  /intent  Toggle intent analysis (clarifying questions)"
    echo "  /model   Change model"
    echo "  /history Show history"
    echo "  /save    Save last output"
    echo "  /clear   Clear screen"
    echo "  /quit    Exit"
    echo ""
    echo -e "${BOLD}Features:${NC}"
    echo "  Intent Analysis - Detects vague prompts and asks clarifying"
    echo "                    questions before improving them"
    echo ""
}

# Main
main() {
    local input_prompt=""
    local output_file=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--file)
                if [ -f "$2" ]; then
                    input_prompt=$(cat "$2")
                else
                    echo -e "${RED}File not found: $2${NC}"
                    exit 1
                fi
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -m|--model)
                MODEL="$2"
                shift 2
                ;;
            --no-intent)
                INTENT_MODE="off"
                shift
                ;;
            --no-logo)
                SHOW_LOGO="false"
                shift
                ;;
            *)
                input_prompt="$1"
                shift
                ;;
        esac
    done

    if [ -n "$input_prompt" ]; then
        non_interactive "$input_prompt" "$output_file"
    else
        interactive_mode
    fi
}

main "$@"
