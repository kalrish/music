set -e

function get_flac_tag
{
	local flac_filename="${1}"
	local tag_name="${2}"

	metaflac \
		"--show-tag=${tag_name}" \
		-- \
		"${flac_filename}" | sed -e "s/^${tag_name}=//"
}

zip_path="${1:?ZIP path not specified}"
target_dir="${2:?target directory not specified}"
artist_dir="${3:?artist directory not specified}"
album_dir="${4:?album directory not specified}"

extract_dir="${artist_dir}/${album_dir}"

mkdir \
	--verbose \
	--parents \
	-- \
	"${extract_dir}" \
	#

unzip \
	-u \
	-d "${extract_dir}" \
	-- \
	"${zip_path}" \
	#

cd \
	"${extract_dir}" \
	#

album_path="${target_dir}/${artist_dir}/${album_dir}"

mkdir \
	--verbose \
	--parents \
	-- \
	"${album_path}" \
	#

mustup_manifest_yaml_path="${album_path}/mustup-manifest.yaml"

{
	echo '---'

	for flac_filename in *.flac
	do
		wave_filename="${flac_filename}"
		wave_filename="${wave_filename#* - * - }"
		wave_filename="${wave_filename/ /-}"
		wave_filename="${wave_filename// /_}"
		wave_filename="${wave_filename//\'/}"
		wave_filename="${wave_filename,,}"
		wave_filename="${wave_filename%.flac}.wave"

		wave_path="${target_dir}/${artist_dir}/${album_dir}/${wave_filename}"

		flac \
			--decode \
			"--output-name=${wave_path}" \
			-- \
			"${flac_filename}" \
			#

		title="$(
			get_flac_tag \
				"${flac_filename}" \
				TITLE \
				#
		)"

		echo
		echo "${wave_filename}:"
		echo '   metadata:'
		echo '      tags:'
		echo '         common:'
		echo "            title: ${title}"
	done
} > "${mustup_manifest_yaml_path}"

# Check that the generated `mustup-manifest.yaml` is valid YAML
yamllint \
	-- \
	"${mustup_manifest_yaml_path}" \
	#

if [[ -e cover.jpg ]]
then
	cp \
		--verbose \
		--no-clobber \
		-- \
		cover.jpg \
		"${album_path}/cover-front.jpeg" \
		#
fi

metaflac \
	--export-tags-to - \
	-- \
	*.flac \
	#
