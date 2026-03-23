#!/bin/bash
die () { # exit with error
    echo >&2 "$@"
    exit 1
}

# recurrent dependecy search
dependencySearch() {
	currentDir="$1"
	searchDep=$(remove_directory "$2" "$currentDir")
	res="$currentDir"
	
	while read -r d; do # loop through directories 
		if [ "$(echo "$res" | grep -E -c "$d")" == 0 ]; then
			dep="$(jq -r '.dependencies' < "$d"/package.json | grep -E -c "$currentDir")"
			if [ "$dep" != "0" ]
			then 
				newDep="$(dependencySearch "$d" "$searchDep")"
				subst="s/(($(echo "$newDep" | sed -r 's/\\n/)|(/g')))//g"
				res="$(echo "$res" | sed -r "$subst")"
				res="$res\n$newDep"
			fi
		fi
	done <<< "$(echo "$searchDep" | tr "|" "\n")"
	
	echo "$res"
}

# remove from directories concatenated with '|' a specific directory 
remove_directory() {
	local haystack="$1"
    local needle="$2"

    haystack="${haystack//$needle|/}"
    haystack="${haystack//|$needle/}"
    haystack="${haystack//$needle/}"

    echo "$haystack"
}

# remove from directories concatenated with '|'' all the possible node_modules
remove_node_modules() {
	local input="$1"

	# old modules "__node_modules"
	input=$(remove_directory "$input" "__node_modules")
	# "node_modules"
	input=$(remove_directory "$input" "node_modules")

	echo "$input"
}

if ! command -v "jq" &> /dev/null
then
    die "Error: jq is not installed. Please install it to continue: 'curl -k -L -o /usr/bin/jq.exe https://github.com/stedolan/jq/releases/latest/download/jq-win64.exe'"
fi


if [ "$#" -eq 0 ]; then
	searchDep="$(echo */ | tr -d / | tr " " "|")" # get all directories name separated by a |ù
	searchDep=$(remove_node_modules "$searchDep")
	declare -A order # map for number of occurencies

	# count dependencies for each module
	while read -r d; do # loop through directories 
		 # count dependencies excluding current base directory name
		tmp=${searchDep//$d|}
		tmp=${tmp//|$d}
		tmp=${tmp//$d}
		dep="$(jq -r '.dependencies' < "$d"/package.json | grep -E -c "$tmp")"
		# append directory in the array cell corresponding to the number of dependencies that it has
		if [ "${order[$dep]+abc}" ]
		then 
			order["$dep"]="${order[$dep]}|$d"
		else
			order["$dep"]="$d"
		fi
	done <<< "$(echo "$searchDep" | tr "|" "\n")"

	# sort module from lowest to highest number of dependencies
	length="$(echo "$searchDep" | tr "|" "\n" | wc -l)"
	length="$((length-1))"
	searchDep=""
	for i in $(seq 0 $length); do # for(int i = 0; i < #modules; i++)
		if [ "${order[$i]}" != "" ] # if we have at least a dependency at that number
		then 
			if [ "${searchDep}" != "" ] # build a sorted searchDep
			then 
				searchDep="$searchDep|${order[$i]}"
			else
				searchDep="${order[$i]}"
			fi
		fi
	done

	# print correct order of modules to build
	while [ "$searchDep" != "" ]; do
		while read -r d; do
			tmp=${searchDep//$d|}
			tmp=${tmp//|$d}
			tmp=${tmp//$d}
			dep="$(jq -r '.dependencies' < "$d"/package.json | grep -E -c "$tmp")"
			if [ "$dep" == "0" ] || [ "$tmp" == "" ] 
			then
				echo "$d"
				searchDep="$tmp"
			fi
		done <<< "$(echo "$searchDep" | tr "|" "\n")"
	done
elif [ "$#" -eq 1 ] || [ "$2" == "N" ]; then
	if [[ "$1" == *"node_modules"* ]]; then
		die "Cannot release node-modules"
	fi
	
	cd "$1" || die "Module not found in the current directory"
	cd .. || die "cd back failed"
else
	if [ "$2" == "Y" ]; then
		searchDep="$(echo */ | tr -d / | tr " " "|")" # get all directories name separated by |
		searchDep=$(remove_node_modules "$searchDep")
		echo -e "$(dependencySearch "$1" "$searchDep" | sed -r 's/(\\n)+/\\n/g')"
	else 
		die "Complete mode parameter has a wrong format (Y/N)"
	fi
fi