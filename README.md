# scriptbin

# Add to Bashrc - to perminently export all directories in `$HOME/.local/bin/`
- the script will temporarly export path regardless
  ```bash
  for dir in $HOME/.local/bin/*; do
      if [ -d "$dir" ]; then
          PATH="$dir:$PATH"
      fi
  done
  export PATH
  ```
