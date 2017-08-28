#!/usr/bin/env bash

# This tool will add new mail distribution groups in LDAP using mail attributes from postfix-book.schema.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# check if we have admin rights
[[ $EUID -ne 0 ]] && echo "I need root to add new groups in LDAP" && exit 1

# define colors
blue="\033[1;34m"
cyan="\033[1;36m"
green="\033[1;32m"
red="\033[1;31m"
white="\033[1;37m"
yellow="\033[1;40m"
reset="\033[0m"

# LDAP info
ldapadmin="cn=Manager,dc=example,dc=com"
mailgroupdn="ou=Groups,ou=Mail,dc=example,dc=com"
domainlist=('domain1' 'domain2' 'domain3' 'domain4' 'domain5' 'domain6' 'domain7' 'domain8')
ldapworkdir="/some/path/to/ldap/scripts/mail/groups"

## Gather Group and Domain names
# Group Name
while true; do
    echo -ne "Email Group Name$blue:$reset "
    read mailgroup
#mailgroup=$(echo "$first.$last" | tr "[:upper:]" "[:lower:]")
    mailgroup=$(echo "$mailgroup" | tr "[:upper:]" "[:lower:]")

    if [[ -z "$mailgroup" ]]; then
        echo
        printf "%s\n" "The Group Name CAN NOT be blank"
        echo
        continue #Skips the rest of the loop and starts again from the top.
    fi

     $(command -v ldapsearch) -xLLL -b "$mailgroupdn" | grep "cn=$mailgroup"
     if [[ $? -eq 0 ]]; then
       echo
       printf "%s\n" "$mailgroup exists in LDAP"
       echo
       continue #Skips the rest of the loop and starts again from the top.
     fi

    #If execution reaches this point, both above checks have been passed
    break #exit while loop, since we've got a valid group
  done

# Mail domain menu
    echo ""
    echo -e "$blue==================$reset"
    echo -e "$white MAIL DOMAIN MENU$reset"
    echo -e "$blue==================$reset"
    array=$(printf "%s\n" "${domainlist[@]}")
    echo "$array"
    echo ""
  
    # Get domain
	echo -ne "Enter the domain to use for the mail group$blue:$reset "
	read domain
	domain=$(echo "$domain" | tr "[:upper:]" "[:lower:]")
	while [[ -z "$domain" ]]; do
        echo ""
        printf "%s\n" "The Domain Name CAN NOT be blank"
        echo ""
        echo -ne "Enter the domain to use for the mail group$blue:$reset "
        read domain 
	domain=$(echo "$domain" | tr "[:upper:]" "[:lower:]")
	done

        array=$(printf "%s\n" "${domainlist[@]}")
      
  	case $domain in
        "${domainlist[0]}")
            echo -e "creating mail group on $blue"${domainlist[0]}"$reset";;
        "${domainlist[1]}")
            echo -e "creating mail group on $blue"${domainlist[1]}"$reset";;
        "${domainlist[2]}")
            echo -e "creating mail group on $blue"${domainlist[2]}"$reset";;
        "${domainlist[3]}")
            echo -e "creating mail group on $blue"${domainlist[3]}"$reset";;
        "${domainlist[4]}")
            echo -e "creating mail group on $blue"${domainlist[4]}"$reset";;
        "${domainlist[5]}")
            echo -e "creating mail group on $blue"${domainlist[5]}"$reset";;
        "${domainlist[6]}")
            echo -e "creating mail group on $blue"${domainlist[6]}"$reset";;
        "${domainlist[7]}")
            echo -e "creating mail group on $blue"${domainlist[7]}"$reset";;
    	*)  echo -e "\033[1;31mInvalid Domain$reset" && exit 1
esac

# Set description to distribution group's name and mail domain
description="$mailgroup email distribution group"

# First create LDAP working dir if it does not exist, then temporarily save basic info to create mailgroup.ldif
if [[ ! -d "$ldapworkdir" ]];
then
  mkdir -p "$ldapworkdir"
fi

sed "s/mailgroup/$(echo $mailgroup)/g" "$ldapworkdir/mailgroup.ldif" > "$ldapworkdir/temp"
sed "s/domain/$(echo $domain)/g" "$ldapworkdir/temp" > "$ldapworkdir/temp2"

# Only the LDAP admin can write new entries
ldapadd -D "$ldapadmin" -y ~/.pwf < "$ldapworkdir/temp2"

if [[ $? -eq 0 ]]; then
        echo -e "\033[1;32mSuccessfully added Email Distribution Group$reset"
        rm "$ldapworkdir/temp"
        rm "$ldapworkdir/temp2"
else
        echo -e "\033[1;31mThe Mail Group Could Not Be Added$reset"
        rm "$ldapworkdir/temp"
        rm "$ldapworkdir/temp2"
        exit 1
fi

exit 0
