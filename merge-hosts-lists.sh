#!/usr/bin/env sh

set -eu
set -x

download_list() {
  url="$1"
  _output_file="$2"
  echo "Downloading $url..."
  curl -sL "$url" -o "$_output_file"
}

# clean the downloaded file
# * start reading at the passed begin_marker (optional)
# * remove comments
# * empty lines
# * remove 0.0.0.0 from the beginning of the line
# * remove comments at the end of the line
clean_list() {
  _input_file="$1"
  _begin_marker="${2:-}"
  _output_file="$3"

  if [ -n "$_begin_marker" ]; then
    awk "/$_begin_marker/,0" "$_input_file"
  else
    cat "$_input_file"
  fi | grep -v '^[[:space:]]*#' | \
      grep -v '^$' | \
      sed 's/^0\.0\.0\.0\s*//; s/[[:space:]]*#.*$//' > "$_output_file"
}

merge_lists() {
  _output_file="$1"
  shift
  echo "Merging lists into $_output_file..."
  cat "$@" | sort -u > "$_output_file"
}


# Main script
# Usage: ./merge-hosts-lists.sh config_file output_file
# config_file: YAML file with a list of URLs and optional begin markers
# output_file: File to save the merged hosts list
#
# Example config file format:
# hosts_lists:
#   - name: stevenblack
#     url: https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
#     begin_marker: "# Start StevenBlack"
#   - name: hagezi
#     url: https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt
main() {
  config_file="$1"
  target_file="$2"

  if [ ! -f "$config_file" ]; then
    echo "Config file not found: $config_file"
    exit 1
  fi

  # Parse the YAML config file
  urls=$(yq '.hosts_lists[] | .url' "$config_file")

  temp_files=""
  for url in $urls; do
    echo "Processing URL: $url"
    _begin_marker=$(yq ".hosts_lists[] | select(.url == \"$url\") | .begin_marker // \"\"" "$config_file")
    name=$(yq ".hosts_lists[] | select(.url == \"$url\") | .name" "$config_file")
    echo "Processing URL: $url with begin marker: $_begin_marker"
    download_list "$url" "$name"
    temp_file=$(mktemp "/tmp/hosts_list_XXXXXX")
    clean_list "$name" "$_begin_marker" "$temp_file"
    temp_files="$temp_files $temp_file"
  done

  merge_lists "$target_file" $temp_files

  # Clean up temporary files
  for temp_file in $temp_files; do
    rm -f "$temp_file"
  done
}

main "$@"
