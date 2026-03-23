#!/bin/bash

find ./ -maxdepth 1 -type d -name '??*' -print0 | while IFS= read -r -d '' d # all directories exluding links
do
	BD=$(basename "$d") # base name of the directories 
	# exclude modules
	if [ "$BD" != 'node_modules' ] 
	then
		echo "Entering this module: $BD"
		(
			cd "$BD" || echo "Failed to CD"
		
			echo "Pruning"
			exec 3>&1
			exec 1> >(paste /dev/null -)
			git fetch --prune || echo "Failed to prune"
			exec 1>&3 3>&-

			echo "Cleaning local branches"
			exec 3>&1
			exec 1> >(paste /dev/null -)
			git branch -vv | grep ': gone]' || echo "Failed to clean"
		)
	fi
done
echo ""
echo "Done"