#!/usr/bin/env bash

set -e

# Get valid shells from /etc/shells
# Only include shells in /bin and exclude anything in /usr
mapfile -t SHELLS < <(
    grep -v '^#' /etc/shells \
    | grep '^/bin/' \
    | grep -E '/(bash|zsh|fish|sh|dash|ksh|tcsh)$' \
    | sort -u
)

# If no shells found
if [ ${#SHELLS[@]} -eq 0 ]; then
    echo "No valid /bin shells found in /etc/shells"
    exit 1
fi

echo
echo "Select your default shell:"
echo "--------------------------------"

# Print numbered list
for i in "${!SHELLS[@]}"; do
    printf "%d) %s\n" $((i+1)) "${SHELLS[$i]}"
done

echo
read -rp "Enter number: " selection

# Validate input
if ! [[ "$selection" =~ ^[0-9]+$ ]] || \
  [ "$selection" -lt 1 ] || \
  [ "$selection" -gt "${#SHELLS[@]}" ]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

CHOICE="${SHELLS[$((selection-1))]}"

echo
read -rp "Change default shell to $CHOICE? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Change shell
chsh -s "$CHOICE"

echo
echo "✔ Default shell changed to $CHOICE"
echo "Log out and back in for it to take effect."