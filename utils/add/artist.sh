set -e

dir="${1:?artist directory not specified}"

artist="$(yq -r .tags.common.artist -- "${dir}/mustup-metadata.yaml")"

git add -- "${dir}/mustup-metadata.yaml"
git commit -m "Add artist ${artist}"
