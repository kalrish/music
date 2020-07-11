set -e

artist_dir="${1:?artist directory not specified}"
album_dir="${2:?album directory not specified}"

artist="$(yq -r .tags.common.artist -- "${artist_dir}/mustup-metadata.yaml")"
album="$(yq -r .tags.common.album -- "${artist_dir}/${album_dir}/mustup-metadata.yaml")"

git add -- "${artist_dir}/${album_dir}"
git commit -m "Add album ${album} by ${artist}"
