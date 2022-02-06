# sh -- export.sh home /run/media/kalrish/music/music
# sh -- export.sh honor10 honor10:/sdcard/Music

profile="${1:?profile not specified}"
target_dir="${2:?target directory not specified}"

#	--dry-run \
rsync \
	--verbose \
	--recursive \
	--exclude .gitignore \
	--exclude tup.config \
	--exclude '*.jpeg' \
	--exclude '*.png' \
	--exclude '*.vc' \
	--times \
	--delete-during \
	--inplace \
	--no-perms \
	--chmod=ugo=rwX \
	--progress \
	--rsh=ssh \
	-- \
	"output-${profile}/" \
	"${target_dir}/vibes" \
	#
