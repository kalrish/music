set -e


for dir in "$@"
do
	for old in "${dir}"/*.s3.yaml
	do
		new="${old%%.s3.yaml}.origin.yaml"
		python -- fix.py "${old}"
		git rm "${old}"
		git add "${new}"
	done
done

git commit --fixup HEAD
