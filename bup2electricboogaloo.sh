#!/bin/bash
#Script to backup my DietPi logs and the DietPi internal backup off of the USB stick

#I have now realised I probably could've just used bupper. But I am enjoying writing this, so.
#bupper: https://github.com/tobru/bupper


#Basic functions
yell() { echo "$0: $*" >&2; }
die() { yell "${@:2} ($1)"; exit $1; }
try() { "$@" || die $? "cannot $*"; }
printline() { printf -- '-%.0s' {1..$(tput cols)} ; printf '\n'; }

#Setup vars
#THE LACK OF A TRAILING SLASH ON ANY PATH IS IMPORTANT AND RELIED UPON BY THE SCRIPT
indpath=/bup/index
project=/testingproj #$project is the name of the project/stack being backed up. It's used for the index path in bup init.
projroot=/home/leo/testingproj #$projroot is the root of the project folder - a seperate index will be created for each subdirectory in this path.
testmode=0
#TODO Implement checks for trailing slash. Search cheatsheet for substrings

function main() {

readarray -t names < <(find $projroot/ -mindepth 1 -maxdepth 1 -type d | sed "s,${projroot},,g")
IFS=$'\n' names=($(sort <<<"${names[*]}")); unset IFS
#This runs find on $projroot with a min/max directory depth of 1, searching for directories only. It then sed's it so remove $projroot
#so we have just the names of the directories we want to backup. This is all then fed into readarray to make the array "$names".
#We then sort them, because it looks nicer in the output.

readarray -t namesnoslash < <(find $projroot/ -mindepth 1 -maxdepth 1 -type d | sed "s,${projroot}/,,g")
IFS=$'\n' namesnoslash=($(sort <<<"${namesnoslash[*]}")); unset IFS
#Run it again. First one leaves in the preceding "/" in each element, this one makes a version without it by adding a "/" to the end of the replacement pattern. It should sort the same, right?
#We want a version without the slash so that the remote server side of each bup command can make ${project}-${namenoslash} rather than a subdirectory, as bup apparently doesn't autocreate subdirectories??
#Could probably ssh into the remote and make the subdirectory ourselves but that sounds like a lot of effort. So..

total=${#names[@]} #This counts how many elements the array $names has, and sets $total to that value.
total2=${#namesnoslash[@]} #..Also gonna count how many are in the 2nd version of it, because I don't really trust it to always give an identical number of elements.
#I can't see why it wouldn't, but I can't see much of anything to be fair. I'm not a programmer. I'm just a bloke with a keyboard.


if [[ $total != $total2 ]]; then
    printf '%s\n\n' "OH SHIT, TOTALS DONT MATCH"
    die #That's how little I trust this shit.
fi


#Check if the index folder exists, if it doesn't, then attempt to make it. Will die on failure.
if [ ! -d $indpath$project ]; then
    createprojectfolder
fi


printf '%s\n\n' "Bupping!"

count=0
for el in ${!names[@]} #For each element in the names/namesnoslash arrays, do some shit.
do
    count+=1
    printline
    printf '%s\n' "Backup "$count" of "$total": "$namenoslash""
    bup_init    #inloop
    bup_index   #inloop
    #TODO Implement bup_save function
done
#TODO Implement using element number $el in each iteration of the loop
} #HERE ENDS MAIN()





#Script specific functions
#Function to create the project folder in index
function createprojectfolder () {
    printf '%s\n' ""$project" index folder doesn't exist. Attempting to create."
    if mkdir -m 777 $indpath$project; then
        printf '%s\n' "Created "$project" index folder."
        chown $indpath$project
    else
        printf '%s\n' "Couldn't create "$project" index folder."
        die
    fi
}


#Function to initialise the index for an element of the project
function bup_init () { #inloop
    if [[ $testmode == 0 ]]; then
        printf '%s\n' "bup -d "$indpath""$project""$name" init -r BupServer:/bup"$project""$namenoslash""
        bup -d $indpath$project$i init -r BupServer:/bup$project$i
    else
        printf '%s\n' "bup -d "$indpath""$project""$name" init -r BupServer:/bup"$project""$namenoslash""
    fi
}


#Function to index the element of the project
function bup_index () { #inloop
    if [[ $testmode == 0 ]]; then
        printf '%s\n' "bup -d "$indpath""$project""$name" index --check "$projroot""$namenoslash""
        bup -d $indpath$project$i index --check $projroot$i
    else
        printf '%s\n' "bup -d "$indpath""$project""$name" index --check "$projroot""$namenoslash""
    fi
}

main; exit
