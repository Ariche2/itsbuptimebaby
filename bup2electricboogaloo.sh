#!/bin/bash
#Script to backup my DietPi logs and the DietPi internal backup off of the USB stick
project=LEO-DHCP
projroot=/mnt/nfs/export/
testmode=1
#$project is the name of the project/stack being backed up. It's used for the index path in bup init.
#$projroot is the root of the project folder - a seperate index will be created for each subdirectory in this path.




readarray -t names < <(find $projroot -mindepth 1 -maxdepth 1 -type d | sed "s,${projroot},,g") #This runs find on $projroot with a min/max depth of 1, for directories. It then sed's it so remove $projroot so we have just the names of the directories we want to backup. This is all then fed into readarray to make the array "$names".
total=${#names[@]} #This counts how many elements the array $names has, and sets $total to that value.

main () {
    
#Check to see if project folder exists in /bup/index/
if [[ $project != $(find /bup/index/ -mindepth 1 -maxdepth 1 -type d | sed "s,/bup/index/,,g") ]]; then
    #If it doesn't, make it
    printf '%s\n\n' "$project index folder doesn't exist. Creating."
    mkdir /bup/index/$project
fi


printf '%s\n\n' "Running bup backup..."
count=0
for i in "${names[@]}"
do
    count=$[ $count + 1 ]
    eval printf -- '-%.0s' {1..$(tput cols)} && printf '\n'
    printf '%s\n' "Backup $count of $total: $i"
    #bup_init
    #bup_index
done
}


#Functions

#Function to initialise the index for an element of the project
bup_init () {
    if [[ $testmode == 0 ]]; then
        bup -d /bup/index/$project/$i init -r BupServer:/bup/$project/$i
    else
        printf '%s\n' "bup -d /bup/index/$project/$i init -r BupServer:/bup/$project/$i"
    fi
}

#Function to index the element of the project
bup_index () {
    if [[ $testmode == 0 ]]; then
        bup -d /bup/index/$project/$i index --check $projroot/$i
    else
        printf '%s\n' "bup -d /bup/index/$project/$i init -r BupServer:/bup/$project/$i"
    fi
}

main; exit
