#!/bin/sh

if [ $# -ne 1 ]; then
	echo "expecting 1 argument, the source chart directory"
	exit 1
fi

srcDir=$1
chartName=$(basename $srcDir)
chartDir=$(basename $(dirname $srcDir))

# clean up old chart
rm -rf $chartDir/$chartName
mkdir -p $chartDir/$chartName
# copy new one here (include dot-files)
cp -r $srcDir/* $chartDir/$chartName
cp -r $srcDir/.* $chartDir/$chartName

