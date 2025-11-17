#!/bin/sh

if [ $# -ne 1 ]; then
	echo "expecting 1 argument, the source chart directory"
	exit 1
fi

# to normalize cp behavior below, remove trailing /s
srcDir=$(echo $1 | sed -e 's|/*$||')


chartName=$(basename $srcDir)
chartDir=$(basename $(dirname $srcDir))


# clean up old chart
rm -rf $chartDir/$chartName
mkdir -p $chartDir/$chartName
# copy new one here (include dot-files)
# (include / in src to preserve dot files etc)
cp -pRP $srcDir/ $chartDir/$chartName

