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
		
			# if it is required also a checkout
			if [ -n "$1" ] 
			then
				echo "Checking out from first param"
				# execs used to tabulate output
				exec 3>&1
				exec 1> >(paste /dev/null -)
				git checkout "$1" || echo "Failed to checkout"
				exec 1>&3 3>&-
			fi
			
			echo "Pulling"
			exec 3>&1
			exec 1> >(paste /dev/null -)
			git pull || echo "Failed to pull"
			exec 1>&3 3>&-
			
			# if it is required also to build
			if [ -n "$2" ] && [ "$2" == 'Y' ]
				then
				echo "Building"
				exec 3>&1
				exec 1> >(paste /dev/null -)
				npm run build:dev || echo "Failed to build"
				exec 1>&3 3>&-
			fi
		)
	fi
done
echo ""
echo "Done"