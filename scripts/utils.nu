export const GITHUB_REPO = "mert-kurttutan/cecc-linux"
export const GUI_ASSET = "excalibur-control-center-gui"
export const CLI_ASSET = "excalibur-control-center-cli"

export def strip-v [version: string] {
  $version | str trim | str replace -r '^v' ''
}

export def release-tag [version: string] {
  $"v(strip-v $version)"
}

export def require-command [name: string] {
  if (which $name | is-empty) {
    error make $"($name) is required but not installed."
  }
}

export def get-current-version [] {
  let versions = (
    open --raw nix/package.nix
    | parse --regex 'version = "(?P<version>[^"]+)"'
    | get version
  )

  if ($versions | is-empty) {
    "unknown"
  } else {
    strip-v ($versions | first)
  }
}

export def get-latest-version [] {
  require-command gh

  let result = (^gh release view --repo $GITHUB_REPO --json tagName -q '.tagName' | complete)
  if $result.exit_code != 0 {
    let stderr = $result.stderr | str trim
    if ($stderr | is-empty) {
      error make "Failed to fetch latest version from GitHub"
    } else {
      error make $stderr
    }
  }

  strip-v $result.stdout
}
