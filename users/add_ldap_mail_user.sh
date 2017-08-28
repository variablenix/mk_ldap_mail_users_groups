#!/usr/bin/env bash

# This tool will add new mail user accounts in LDAP using mail attributes from postfix-book.schema.

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

# first check if we have admin rights
[[ $EUID -ne 0 ]] && echo "I need root to add new mail users in LDAP" && exit 1

# define colors
blue="\033[1;34m"
cyan="\033[1;36m"
green="\033[1;32m"
red="\033[1;31m"
white="\033[1;37m"
yellow="\033[1;40m"
reset="\033[0m"

# LDAP info
ldapmailou="ou=Mail,dc=example,dc=com"
ldapadmin="cn=Manager,dc=example,dc=com"
mailgroupdn="cn=vmail,ou=Groups,dc=example,dc=com"
domainlist=('domain1' 'domain2' 'domain3' 'domain4' 'domain5' 'domain6' 'domain7' 'domain8')
tempuserpw="itsasecret"
ldapworkdir="/some/path/to/ldap/scripts/mail/users"
maildir="/home/vmail"
mailtemplate='html' # html or plain

## Gather basic info
# firstname
echo -ne "First Name$blue:$reset " 
read first
first=$(echo "${first^}" | tr "[:upper:]" "[:lower:]" | sed -e "s/\b\(.\)/\u\1/g")
while [[ -z "$first" ]]; do
	echo
	printf "%s\n" "The First Name CAN NOT be blank"
  echo
	echo -ne "First Name$blue:$reset "
	read first
	first=$(echo "${first^}" | tr "[:upper:]" "[:lower:]" | sed -e "s/\b\(.\)/\u\1/g")
done

# lastname
echo -ne "Last Name$blue:$reset "
read last
last=$(echo "${last^}" | tr "[:upper:]" "[:lower:]" | sed -e "s/\b\(.\)/\u\1/g")
while [[ -z "$last" ]]; do
	echo
  printf "%s\n" "The Last Name CAN NOT be blank"
  echo
	echo -ne "Last Name$blue:$reset "
  read last
	last=$(echo "${last^}" | tr "[:upper:]" "[:lower:]" | sed -e "s/\b\(.\)/\u\1/g")
done

# username
while true; do
    echo -ne "User Name [uid]$blue:$reset "
    read username
#username=$(echo "$first.$last" | tr "[:upper:]" "[:lower:]")
    username=$(echo "$username" | tr "[:upper:]" "[:lower:]")
    $(command -v ldapsearch) -xLLL -b "$ldapmailou" "(memberOf=$mailgroupdn)" uid \+ * | grep uid: | cut -d ':' -f2 | grep -q "$username"

    if [[ -z "$username" ]]; then
        echo
        printf "%s\n" "The User Name CAN NOT be blank"
        echo
        continue #Skips the rest of the loop and starts again from the top.
    fi

    $(command -v ldapsearch) -xLLL -b "$ldapmailou" "(memberOf=$mailgroupdn)" uid \+ * | grep uid: | cut -d ':' -f2 | grep -q "$username"
    if [[ $? -eq 0 ]]; then
        echo
        printf "%s\n" "$username exists in LDAP"
        echo
        continue #Skips the rest of the loop and starts again from the top.
    fi

    #If execution reaches this point, both above checks have been passed
    break #exit while loop, since we've got a valid username
done

# Mail domain menu
    echo
    echo -e "$blue==================$reset"
    echo -e "$white MAIL DOMAIN MENU$reset"
    echo -e "$blue==================$reset"
    array=$(printf "%s\n" "${domainlist[@]}")
    echo "$array"
    echo
  
    # Get domain
	echo -ne "Enter the domain to use for the mail account$blue:$reset "
	read domain
	domain=$(echo "$domain" | tr "[:upper:]" "[:lower:]")
	while [[ -z "$domain" ]]; do
        echo
        printf "%s\n" "The Domain Name CAN NOT be blank"
        echo
        echo -ne "Enter the domain to use for the mail account$blue:$reset "
        read domain 
	domain=$(echo "$domain" | tr "[:upper:]" "[:lower:]")
	done

        array=$(printf "%s\n" "${domainlist[@]}")
      
  	case $domain in
        "${domainlist[0]}")
            echo -e "creating mail account on $blue"${domainlist[0]}"$reset";;
        "${domainlist[1]}")
            echo -e "creating mail account on $blue"${domainlist[1]}"$reset";;
        "${domainlist[2]}")
            echo -e "creating mail account on $blue"${domainlist[2]}"$reset";;
        "${domainlist[3]}")
            echo -e "creating mail account on $blue"${domainlist[3]}"$reset";;
        "${domainlist[4]}")
            echo -e "creating mail account on $blue"${domainlist[4]}"$reset";;
        "${domainlist[5]}")
            echo -e "creating mail account on $blue"${domainlist[5]}"$reset";;
        "${domainlist[6]}")
            echo -e "creating mail account on $blue"${domainlist[6]}"$reset";;
        "${domainlist[7]}")
            echo -e "creating mail account on $blue"${domainlist[7]}"$reset";;
    	*)  echo -e "\033[1;31mInvalid Domain$reset" && exit 1
esac

# Set mail home & storage directory
mailHomeDirectory="$maildir/$domain/$username@$domain"
mailStorageDirectory="maildir:$maildir/$domain/$username@$domain/Maildir"

# Set description to user's first name and mail domain
description="$first's $domain mail account"

# First create LDAP working dir if it does not exist, then temporarily save basic info to create mailuser.ldif
if [[ ! -d "$ldapworkdir" ]];
then
  mkdir -p "$ldapworkdir"
fi

sed "s/first/$(echo $first)/g" "$ldapworkdir/mailuser.ldif" > "$ldapworkdir/temp"
sed "s/last/$(echo $last)/g" "$ldapworkdir/temp" > "$ldapworkdir/temp2"
sed "s/username/$(echo $username)/g" "$ldapworkdir/temp2" > "$ldapworkdir/temp"
sed "s/domain/$(echo $domain)/g" "$ldapworkdir/temp" > "$ldapworkdir/temp2"

# Only the LDAP admin can write new entries
ldapadd -D "$ldapadmin" -y ~/.pwf < "$ldapworkdir/temp2"

# Set default password (LDAP password policies set by ppolicy)
ldappasswd -s "$tempuserpw" -D "$ldapadmin" -x "uid=$username,$ldapmailou" -y ~/.pwf

# add account to virtual mail access group
ldapmodify -x -D "$ldapadmin" -Z -y ~/.pwf <<!
dn: $mailgroupdn
changetype: modify
add: member
member: uid=$username,$ldapmailou
!

if [[ $? -eq 0 ]]; then
        echo -e "\033[1;32mSuccessfully added Mail account$reset"
        rm "$ldapworkdir/temp"
        rm "$ldapworkdir/temp2"

# Send welcome email
if [[ "$mailtemplate" == "html" ]]; then
  sed "s/username/$(echo $username)/g" "$ldapworkdir/templates/temp.html" > "$ldapworkdir/temp"
  sed "s/domain/$(echo $domain)/g" "$ldapworkdir/temp" > "$ldapworkdir/templates/welcome.html"
elif
  [[ "$mailtemplate" == "plain" ]]; then
  sed "s/username/$(echo $username)/g" "$ldapworkdir/templates/temp-plain.html" > "$ldapworkdir/temp"
  sed "s/domain/$(echo $domain)/g" "$ldapworkdir/temp" > "$ldapworkdir/templates/welcome.html"
fi

  (
  echo To: $username@$domain
  echo From: noreply@$domain
  echo Cc: admin@$domain
  echo "Content-Type: text/html; "
  echo Subject: Welcome to your $domain mail account!
  echo
  cat "$ldapworkdir/templates/welcome.html"
) | sendmail -t

rm "$ldapworkdir/temp"
rm "$ldapworkdir/templates/welcome.html"

else
        echo -e "\033[1;31mMail account could not be added$reset"
        rm "$ldapworkdir/temp"
        rm "$ldapworkdir/temp2"
        exit 1
fi

exit 0
