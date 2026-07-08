#!/usr/bin/env bash
set -euo pipefail

cleanup_dir=""
src_dir=""

cleanup() {
  if [ -n "$cleanup_dir" ] && [ -d "$cleanup_dir" ]; then
    rm -rf "$cleanup_dir"
  fi
}
trap cleanup EXIT

resolve_skill_dir() {
  local root_dir="$1"

  if [ -f "$root_dir/SKILL.md" ]; then
    src_dir="$root_dir"
    return 0
  fi

  if [ -f "$root_dir/github-pr/SKILL.md" ]; then
    src_dir="$root_dir/github-pr"
    return 0
  fi

  return 1
}

resolve_local_src_dir() {
  local script_path="${BASH_SOURCE[0]:-}"
  local script_dir

  if [ -z "$script_path" ]; then
    return 1
  fi

  script_dir="$(cd "$(dirname "$script_path")" 2>/dev/null && pwd -P)" || return 1
  resolve_skill_dir "$script_dir"
}

download_src_dir() {
  local repo="${GITHUB_PR_REPO:-igorrendulic/github-pr-skill}"
  local ref="${GITHUB_PR_REF:-main}"
  local tarball_url="https://codeload.github.com/${repo}/tar.gz/${ref}"
  local entry

  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required for remote install." >&2
    exit 1
  fi

  cleanup_dir="$(mktemp -d "${TMPDIR:-/tmp}/github-pr-install.XXXXXX")"
  curl -fsSL "$tarball_url" | tar -xzf - -C "$cleanup_dir"

  for entry in "$cleanup_dir"/*; do
    if [ -d "$entry" ]; then
      resolve_skill_dir "$entry" && return 0
      break
    fi
  done

  echo "Error: downloaded archive does not contain a github-pr skill." >&2
  exit 1
}

if ! resolve_local_src_dir; then
  download_src_dir
fi

skills_dir="${CODEX_HOME:-"$HOME/.codex"}/skills"
target_dir="$skills_dir/github-pr"

mkdir -p "$skills_dir"
rm -rf "$target_dir"
mkdir -p "$target_dir"

cp "$src_dir/SKILL.md" "$target_dir/SKILL.md"
cp -R "$src_dir/references" "$target_dir/references"
if [ -d "$src_dir/agents" ]; then
  cp -R "$src_dir/agents" "$target_dir/agents"
fi
if [ -d "$src_dir/scripts" ]; then
  cp -R "$src_dir/scripts" "$target_dir/scripts"
fi

echo "Installed github-pr skill to $target_dir"
