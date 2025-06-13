#!/bin/bash

# Agent Send Script - Send messages to specific agents via tmux
# Usage: ./agent-send.sh [agent_name] [message]

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo "Usage: $0 [agent_name] [message]"
    echo "       $0 --list"
    echo ""
    echo "Available agents:"
    echo "  - president"
    echo "  - boss1"
    echo "  - worker1"
    echo "  - worker2"
    echo "  - worker3"
    echo ""
    echo "Example:"
    echo "  $0 boss1 \"Hello, please start the project\""
    echo "  $0 --list"
}

# Function to list active agents
list_agents() {
    echo -e "${BLUE}🤖 Active Agents:${NC}"
    echo "=================="
    
    # Check president session
    if tmux has-session -t president 2>/dev/null; then
        echo -e "${GREEN}✓ president${NC} (session: president)"
    else
        echo -e "${RED}✗ president${NC} (session not found)"
    fi
    
    # Check multiagent session panes
    if tmux has-session -t multiagent 2>/dev/null; then
        echo -e "${GREEN}✓ boss1${NC} (session: multiagent, pane: 0)"
        echo -e "${GREEN}✓ worker1${NC} (session: multiagent, pane: 1)"
        echo -e "${GREEN}✓ worker2${NC} (session: multiagent, pane: 2)"
        echo -e "${GREEN}✓ worker3${NC} (session: multiagent, pane: 3)"
    else
        echo -e "${RED}✗ boss1${NC} (multiagent session not found)"
        echo -e "${RED}✗ worker1${NC} (multiagent session not found)"
        echo -e "${RED}✗ worker2${NC} (multiagent session not found)"
        echo -e "${RED}✗ worker3${NC} (multiagent session not found)"
    fi
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

if [ "$1" == "--list" ]; then
    list_agents
    exit 0
fi

if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing message argument${NC}"
    show_usage
    exit 1
fi

AGENT=$1
MESSAGE=$2

# Create log directory if it doesn't exist
mkdir -p ./logs

# Log timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Function to send message to agent
send_to_agent() {
    local session=$1
    local pane=$2
    local agent_name=$3
    local msg=$4
    
    if tmux has-session -t $session 2>/dev/null; then
        # Send the message
        tmux send-keys -t $session:0.$pane "$msg" C-m
        
        # Log the message
        echo "[$TIMESTAMP] $agent_name <- $msg" >> ./logs/send_log.txt
        
        echo -e "${GREEN}✅ Message sent to $agent_name${NC}"
        echo -e "${YELLOW}📝 Message: $msg${NC}"
        return 0
    else
        echo -e "${RED}❌ Error: Session '$session' not found${NC}"
        echo -e "${YELLOW}💡 Tip: Run ./setup.sh first${NC}"
        return 1
    fi
}

# Route message to appropriate agent
case $AGENT in
    "president")
        send_to_agent "president" "0" "president" "$MESSAGE"
        ;;
    "boss1")
        send_to_agent "multiagent" "0" "boss1" "$MESSAGE"
        ;;
    "worker1")
        send_to_agent "multiagent" "1" "worker1" "$MESSAGE"
        ;;
    "worker2")
        send_to_agent "multiagent" "2" "worker2" "$MESSAGE"
        ;;
    "worker3")
        send_to_agent "multiagent" "3" "worker3" "$MESSAGE"
        ;;
    *)
        echo -e "${RED}❌ Error: Unknown agent '$AGENT'${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac