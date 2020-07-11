# e.g.: /run/media/kalrish/music/sources
sources="${1:?source directory not specified}"
# e.g.: /mnt/vibes
target="${2:?vibes directory not specified}"

find "${sources}" -type f -name mustup-manifest.txt -printf '%P\n' | sed -e 's|/[^/]*$||g' | while read -r dir
do
	mkdir \
		--verbose \
		--parents \
		-- \
		"${target}/${dir}" \
		#

	# re: --no-preserve=all
	# Since I use Exact Audio Copy, I must use Windows.
	# I transfer the files with a USB stick, which must
	# therefore be formatted with a Windows filesystem.
	# For that reason, files often have executable bits.
	cp \
		--verbose \
		--no-clobber \
		--recursive \
		--no-preserve=all \
		-- \
		"${sources}/${dir}/." \
		"${target}/${dir}" \
		#

	rm \
		--verbose \
		-- \
		"${target}/${dir}/mustup-manifest.txt" \
		#

	mustup_manifest_yaml_path="${target}/${dir}/mustup-manifest.yaml"

	# While the contents of the disk are extracted,
	# I write the song titles in `mustup-manifest.txt`,
	# one per line. `mustup-manifest.yaml` can then be
	# generated from that file.
	(
		echo '---'

		cd \
			"${sources}/${dir}" \
			#

		for file in *.wave
		do
			# re: IFS
			# Since I use Exact Audio Copy, I must use Windows, and
			# mustup-manifest.txt has Windows line terminators.
			IFS=$'\r' read -r title

			echo
			echo "${file}:"
			echo '   metadata:'
			echo '      tags:'
			echo '         common:'
			echo "            title: ${title}"
		done < mustup-manifest.txt
	) > "${mustup_manifest_yaml_path}"

	# Check that the generated `mustup-manifest.yaml` is valid YAML
	yamllint \
		-- \
		"${mustup_manifest_yaml_path}" \
		#
done
