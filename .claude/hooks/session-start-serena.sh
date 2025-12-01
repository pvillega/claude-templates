#!/bin/bash
cat << 'EOF'
<user-prompt-submit-hook>
Serena init: call mcp__serena__initial_instructions then mcp__serena__activate_project with project="."
</user-prompt-submit-hook>
EOF
