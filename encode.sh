set -e

top_relative="$1"
image="$2"
output="$3"
top_absolute="${PWD}/${top_relative}"

relative_dir="$(realpath "--relative-to=${top_relative}" "${PWD}")"

container_name="${relative_dir}/${output}"
container_name="${container_name//\//_}"

shift 3

docker \
	run \
	--name "${container_name}" \
	--mount "type=bind,source=${top_absolute},destination=/mnt" \
	-w "/mnt/${relative_dir}" \
	-- \
	"${image}" \
	"$@" \
	#

docker \
	container \
	cp \
	-- \
	"${container_name}:/tmp/output" \
	"${output}" \
	#

docker \
	container \
	rm \
	-- \
	"${container_name}" \
	#
