#!/bin/bash

workdir=/home/leo/workspace/webapps
exclude=bupxclude
composedir=compose.$exclude
tempfile=/tmp/buptemp

echo "Copying any .yml's to webapps/composebup/..." && echo -e && echo -e

cp -v $workdir/*.yml $workdir/$composedir/ && echo -e && echo -e

echo "Finding webapp names..."&& echo -e && echo -e


for webappraw in $workdir/*/
do
#If it's excluded, exclude it. Else, put it in the tempfile
	if [[ "${webappraw:28:-1}" == *"$exclude"* ]]
	then
		echo "---skipped an excluded entry"
	else
#		echo "${webappraw:28:-1}"
		echo "${webappraw:28:-1}" >> /tmp/buptemp
	fi
done

#Count number of lines in tempfile before we add one more
appcount=$(cat $tempfile | wc -l)

#Add a trailing carriage return to the tempfile because reasons
echo -e >> /tmp/buptemp

#Setup $current
let current=1

#Loop through each entry in tempfile and do stuff
cat $tempfile | while read webapp
do
#Check if it's the empty last line and break
	if [ -z "$webapp" ] 
	then 
		break
#Otherwise, do stuff
	else
		echo "("$current"/"$appcount")"$webapp""
		let current=$current+1
	fi
done

#Remove the tempfile so it doesn't cause shit next time
rm $tempfile

exit
