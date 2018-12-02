#!/bin/bash

# Author: Dominik Piasecki
# Last updated 1/20/2017


usage() {
  cat << EOF
    ** Save perms v2 **
    Usage:  save-perms [/src/dir]

    When restoring perms place the file -> restore-permissions.sh <-
    in the directory containing the folder you wish to restore
                                                          T
    Execute restore-permissions.sh as root              .-"-.
                                                       |  ___|
    Example:                                           | (.\/.)
      save-perms /some/directory                       |  ,,,'
      sudo /some/directory/restore-permissions.sh      | '###
                                                        '----'
                                             "It's fun on a bun!"
EOF
    #' Fix syntax highlight on sublime
    exit $1
}


# Trim the paths given to the program and clean them up a bit
target="${1%/}"   # trims trailing / from directory path
destdir=$(dirname "$target")  # sets the destination for the restore file

# if less than 1 argument supplied, display usage
if [  $# -le 0 ]
	then
		usage
		exit
fi

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $1 == "--help") ||  $1 == "-h" ]]
	then
		usage
		exit
fi

# display usage if the script is not run as root user  (depreciated as the script auto elevates!)
#	if [[ $USER != "root" ]]; then
#		echo 'This script must be run as root!'
#		exit
#	fi

if [ ! -d "$target" ]; then
  # Control will enter here if $target doesn't exist.
    echo -e '\nERROR: Source directory does not exist'
    usage
    exit
fi

# Elevate to root
if [ $EUID != 0 ]; then
    echo '-->> Executing script as root! <<--'
    sudo "$0" "$@"
    exit $?
fi

echo -e "\nTarget: $target \nDestination: $destdir"

# Save the perms to a file and make it executable
find "$target" -depth -printf '%m:%u:%g:%p\0' |
awk -v RS='\0' -F: '
    BEGIN {
        print "#!/bin/sh";
        print "set -e";
        print "# display usage if the script is not run as root user"
	      print "if [ $USER != \"root\" ]; then"
		    print "echo \"This script must be run as root!\""
		    print "exit"
        print "fi"
        q = "\047";
    }
    {
        gsub(q, q q "\\" q);
        f = $0;
        sub(/^[^:]*:[^:]*:[^:]*:/, "", f);
        print "chmod", $1, q f q;
        print "chown --", q $2 ":" $3 q, q f q;
    }' > "$destdir"/restore-permissions.sh

# Make the file executable
chmod +x "$destdir"/restore-permissions.sh

echo -e '\n The script to restore folder permissions is located at:\n'
echo -e "$destdir/restore-permissions.sh" '\n'

exit
