#!/usr/bin/env nu

use utils.nu [
  CLI_ASSET
  GITHUB_REPO
  GUI_ASSET
  get-current-version
  get-latest-version
  release-tag
  require-command
  strip-v
]

const GITHUB_RELEASE_BASE = $"https://github.com/($GITHUB_REPO)/releases/download"

def log-info [message: string] {
  print $"(ansi green)[INFO](ansi reset) ($message)"
}

def ensure-in-repository-root [] {
  if (not ("flake.nix" | path exists)) or (not ("nix/package.nix" | path exists)) or (not ("nix/module.nix" | path exists)) {
    error make "flake.nix, nix/package.nix, or nix/module.nix not found. Please run this script from the repository root."
  }
}

def ensure-required-tools-installed [] {
  require-command nix
  require-command nix-prefetch-url
  require-command gh
}

def fetch-url-hash [url: string, --unpack] {
  let result = if $unpack {
    ^nix-prefetch-url --unpack $url | complete
  } else {
    ^nix-prefetch-url $url | complete
  }

  if $result.exit_code != 0 {
    ""
  } else {
    let lines = ($result.stdout | str trim | lines)
    if ($lines | is-empty) {
      ""
    } else {
      $lines | last | str trim
    }
  }
}

def fetch-release-asset-hash [version: string, asset: string] {
  fetch-url-hash $"($GITHUB_RELEASE_BASE)/(release-tag $version)/($asset)"
}

def fetch-source-hash [version: string] {
  fetch-url-hash --unpack $"https://github.com/($GITHUB_REPO)/archive/refs/tags/(release-tag $version).tar.gz"
}

def set-package-version [content: string, version: string] {
  $content | str replace -r 'version = "[^"]*";' $"version = \"($version)\";"
}

def set-module-version [content: string, version: string] {
  $content | str replace -r 'version = "[^"]*";' $"version = \"($version)\";"
}

def set-package-asset-hash [content: string, asset_name: string, hash: string] {
  let pattern = ('(?s)(asset = "' + $asset_name + '";\n\s+sha256 = ")[^"]+(";)')
  let replacement = ('${1}' + $hash + '${2}')
  $content | str replace -r $pattern $replacement
}

def set-module-source-hash [content: string, hash: string] {
  let pattern = '(?s)(ceccSource = pkgs\.fetchzip \{\n\s+url = "https://github\.com/mert-kurttutan/cecc-linux/archive/refs/tags/v\$\{version\}\.tar\.gz";\n\s+sha256 = ")[^"]+(";)'
  let replacement = ('${1}' + $hash + '${2}')
  $content | str replace -r $pattern $replacement
}

def update-to-version [new_version: string] {
  log-info $"Updating to version ($new_version)..."

  let original_package = open --raw nix/package.nix
  let original_module = open --raw nix/module.nix

  mut updated_package = set-package-version $original_package $new_version
  mut updated_module = set-module-version $original_module $new_version

  log-info $"Fetching hash for ($GUI_ASSET)..."
  let gui_hash = fetch-release-asset-hash $new_version $GUI_ASSET
  if ($gui_hash | is-empty) {
    error make $"Failed to fetch hash for ($GUI_ASSET)"
  }

  log-info $"Fetching hash for ($CLI_ASSET)..."
  let cli_hash = fetch-release-asset-hash $new_version $CLI_ASSET
  if ($cli_hash | is-empty) {
    error make $"Failed to fetch hash for ($CLI_ASSET)"
  }

  log-info "Fetching hash for source archive..."
  let source_hash = fetch-source-hash $new_version
  if ($source_hash | is-empty) {
    error make "Failed to fetch hash for source archive"
  }

  $updated_package = set-package-asset-hash $updated_package $GUI_ASSET $gui_hash
  $updated_package = set-package-asset-hash $updated_package $CLI_ASSET $cli_hash
  $updated_module = set-module-source-hash $updated_module $source_hash

  $updated_package | save --force nix/package.nix
  $updated_module | save --force nix/module.nix

  log-info "Verifying package build..."
  let build = (^nix build ".#excalibur-control-center" | complete)
  if $build.exit_code != 0 {
    $original_package | save --force nix/package.nix
    $original_module | save --force nix/module.nix

    let stderr = $build.stderr | str trim
    if ($stderr | is-empty) {
      error make "Build verification failed"
    } else {
      error make {
        msg: "Build verification failed"
        help: $stderr
      }
    }
  }

  log-info "Build successful!"
}

def update-flake-lock [] {
  log-info "Updating flake.lock..."
  ^nix flake update
}

def show-changes [] {
  print ""
  log-info "Changes made:"
  let diff = (^git diff --stat nix/package.nix nix/module.nix flake.lock | complete)
  if ($diff.stdout | str trim | is-not-empty) {
    print ($diff.stdout | str trim)
  }
}

def main [
  --version: string = "" # Update to a specific cecc-linux version.
  --check               # Only check for updates; exit 1 when an update is available.
] {
  ensure-in-repository-root
  ensure-required-tools-installed

  let current_version = get-current-version
  let latest_version = if ($version | is-empty) {
    get-latest-version
  } else {
    strip-v $version
  }

  log-info $"Current version: ($current_version)"
  log-info $"Latest version: ($latest_version)"

  if $current_version == $latest_version and ($version | is-empty) {
    log-info "Already up to date!"
    exit 0
  }

  if $check {
    log-info $"Update available: ($current_version) -> ($latest_version)"
    exit 1
  }

  update-to-version $latest_version
  log-info $"Successfully updated cecc-linux from ($current_version) to ($latest_version)"

  update-flake-lock
  show-changes
}
