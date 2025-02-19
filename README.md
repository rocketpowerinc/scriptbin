# scriptbin

# Bashrc - Export all directories in `$HOME/.local/bin/`
  ```bash
  for dir in $HOME/.local/bin/*; do
      if [ -d "$dir" ]; then
          PATH="$dir:$PATH"
      fi
  done
  export PATH
  ```
