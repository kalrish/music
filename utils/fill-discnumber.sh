album_dir="${1:?album directory not specified}"

cd "${album_dir}"

for disc_dir in */
do
	if [[ ${disc_dir} =~ ^[0-9]+/$ ]]
	then
		disc_number="${disc_dir%/}"
		{
			echo '---'
			echo
			echo 'tags:'
			echo '   Vorbis:'
			echo "      DISCNUMBER: '${disc_number}'"
		} >> "${disc_dir}/mustup-metadata.yaml"
	fi
done
