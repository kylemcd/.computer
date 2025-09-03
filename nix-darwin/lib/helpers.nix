{ }:
{
  # Returns a shell snippet that creates a macOS Login Item for the given app path.
  # Usage in activation script text:
  #   ${openOnLogin { path = "/Applications/Nix Apps/1Password.app"; hidden = false; }}
  openOnLogin = { path, hidden ? false }:
    ''/usr/bin/osascript -e 'tell application "System Events" to make login item at end with properties {path:"${path}", hidden:${if hidden then "true" else "false"}}' '';
}


