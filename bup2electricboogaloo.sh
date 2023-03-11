#!/bin/bash
#Script to backup my DietPi logs and the DietPi internal backup off of the USB stick

#I have now realised I probably could've just used bupper. But I am enjoying writing this, so.
#bupper: https://github.com/tobru/bupper

#########################################################
#                                                       #
#         You should read the fucking to do's           #
#                   you dopey fuck                      #
#   (and DONT spend 10m looking for a to do tracker)    #
#                                                       #
#########################################################


function main() {

#Check if the index folder exists, if it doesn't, then attempt to make it. Will die on failure.
if [ ! -d "$indroot_project" ]; then
    createprojectfolder
fi


printf '%s\n\n' "Bupping!"; printline
declare -i count && count=0
for el in "${!name[@]}" #For each element in the name/namenoslash arrays, init it, index it, and save it.
do
    count+=1
    printf '%s\n' "Backup $count of $total: ${namenoslash[$el]}"
    bup_init    #inloop
    bup_index   #inloop
    # TODO 6 Implement bup_save function (have copied bup_index, needs editing)
    printline
done
# TODO 10 Implement "-n $backupname". Probably set it to todays date? IT HAS TO GO BEFORE --check AFAIK - see line 4 of the first example on the bup index manpage
# TODO 11 Dependent on 10 - set up automated culling of old backups. Easy option - see "bup-prune-older"

} #HERE ENDS MAIN()



# TODO 9 Setup variable definition function
# Do not worry about vars defined in a function not applying globally - apparently they just fucken do? (probably because we're not using it in a command substitution?)

#Script specific definition function
function definevars () {
    
    #Define root vars
    #THE LACK OF A TRAILING SLASH ON ANY OF THESE PATHS IS IMPORTANT AND RELIED UPON BY THE SCRIPT - see td 2
    indroot=/bup/index #the base path to the bup index
    project=/testingproj #$project is the name of the project/stack being backed up. It's used for the index path in bup init.
    projroot=/home/leo/testingproj #$projroot is the root of the project folder - a seperate index will be created for each subdirectory in this path.
    testmode=1 #If this is 0, it's a real run. If it's anything else, dry run. Check this is actually true before running, PLEASE DEAR GOD. sleep deprived fucker.
    # TODO 2 Implement sanitising for trailing slashes. Search cheatsheet for substrings - also see https://unix.stackexchange.com/a/423552
    # TODO 3 Could simplify by grabbing $project from $projroot? see https://unix.stackexchange.com/a/423552
    
    readarray -t name < <(find $projroot/ -mindepth 1 -maxdepth 1 -type d | sed "s,${projroot},,g")
    readarray -t name < <(printf '%s\n' "${name[@]}"|sort)
    #This runs find on $projroot with a min/max directory depth of 1, searching for directories only. It then sed's it so remove $projroot
    #so we have just the names of the directories we want to backup. This is all then fed into readarray to make the array "$name".
    #We also sort them by using printf to add an newline to the end of each element, and then feeding the elements into sort. Then it's fed back into the array.
    #Then it's run a second time to make a version of $name without a preceding slash for use in the remote path.
    readarray -t namenoslash < <(find $projroot/ -mindepth 1 -maxdepth 1 -type d | sed "s,${projroot}/,,g")
    readarray -t namenoslash < <(printf '%s\n' "${namenoslash[@]}"|sort)

    # TODO 5 replace use of sed in these two with bash parameter expansion - sub-string removal.
    # see https://unix.stackexchange.com/a/423552
    
    
    #Define dependent vars
    #build some better variables out of the shit we have
    #theoretical $project define here - see td 3 
    indroot_project="$indroot""$project"
    total=${#name[@]} #This counts how many elements the array $names has, and sets $total to that value.
    total2=${#namenoslash[@]} #..Also gonna count how many are in the 2nd version of it, because I don't really trust it to always give an identical number of elements.

    #Just a little test that hopefully never ever triggers.
    if [[ $total != "$total2" ]]; then
        printf '%s\n\n' "OH SHIT, TOTALS DONT MATCH"
        echo total is "$total"
        echo total2 is "$total2"
        #die #That's how little I trust this shit.
    fi
}


#Script specific action functions
#Function to create the project folder in index
function createprojectfolder () {
    printf '%s\n' "$project index folder doesn't exist. Attempting to create."
    if mkdir -m 777 $indroot$project; then
        printf '%s\n' "Created $project index folder."
        chown $indroot$project
    else
        printf '%s\n' "Couldn't create $project index folder."
        die
    fi
}



#Function to bup init the path for an element of the project
function bup_init () { #inloop
    #Print the command
    printf '%s\n' "bup -d ${indroot_project}${name[$el]} init -r BupServer:/bup${project}_${namenoslash[$el]}"

    if [[ $testmode == 0 ]]; then
        #Run it for real
        bup -d "$indroot_project""${name[$el]}" init -r BupServer:/bup "$project"_"${namenoslash[$el]}"

    fi
}


#Function to bup index the path for an element of the project
function bup_index () { #inloop
    #Print the command
    printf '%s\n' "bup -d ${indroot_project}${name[$el]} index --check ${project}_${namenoslash[$el]}"
    
    if [[ $testmode == 0 ]]; then
        #Run it for real    
        bup -d "$indroot_project""${name[$el]}" index --check "$projroot"_"${namenoslash[$el]}"

    fi
}


#Function to bup save the path for an element of the project
function bup_save () { #inloop
    #Print the command
    printf '%s\n' "bup -d ${indroot_project}${name[$el]} index --check ${project}_${namenoslash[$el]}"
    
    if [[ $testmode == 0 ]]; then
        #Run it for real       
        bup -d "$indroot_project""${name[$el]}"  index --check "$projroot"_"${namenoslash[$el]}"

    fi
}

#Basic functions
yell() { echo "$0: $*" >&2; }
die() { yell "${@:2} ($1)"; exit "$1"; }
try() { "$@" || die $? "cannot $*"; }
printline() { printf -- '%.s─' $(seq 1 "$(tput cols)") ; printf '\n'; } # https://stackoverflow.com/a/64267019
# TODO 1 replace printline in utils/printline and utils/funcs with the one here as it actually works lol

#run the functions!
definevars && echo "${name[@]}" #&& main; exit
