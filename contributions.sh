#!/bin/bash

# adding count lines command alias
git config --global alias.count-lines "! git log --author=\"\$1\" --pretty=tformat: --numstat | awk '{ add += \$1; subs += \$2; loc += \$1 - \$2 } END { printf \"added lines: %s, removed lines: %s, total lines: %s\n\", add, subs, loc }' #"

# list of unique authors
authors=$(git log -s --format='%ae' | sort -u)

declare -A result # map <#changed lines, count-lines output>
tot=0 #tot lines changed in the project
for author in $authors; do # loop over authors
	cnt="$(git count-lines "$author";)" # get count-lines output
	t="${cnt##*total lines: }" # get tot changed lines for each authors from count-lines output
	if [ "$t" != "" ]
	then
		tot="$((tot + t))" # update overall total
		result["$t"]="$({ echo "$author => "; echo "$cnt"; } | tr "\n" " ")" # put value in the map
	fi
done

keys=("${!result[@]}") #get map keys
while [[ ${#keys[@]} -gt 0 ]]; do # iterate while there are keys
	# get current key and value
    key=${keys[0]} 
    value=${result[$key]}
	# compute percentage of contributions
	perc="$( awk -v var1="$key" -v var2="$tot" 'BEGIN { print  ( var1 / var2 * 100) }')"
    echo "$value($perc%)" # output that value to console
	
	# delete used key
    unset "keys[0]"
    keys=("${keys[@]}")
done