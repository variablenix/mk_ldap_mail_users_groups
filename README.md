# Creating mail users and distribution groups in LDAP

## Mail Accounts
This tool interactively gathers some preliminary information and creates an email account using an objectClass and user attributes from [pastfix-book.schema](https://github.com/variablenix/ldap-mail-schema/blob/master/postfix-book.schema). This tool also assumes there is a `~/.pwf` file that exists containing the LDAP admin credentials so that write access is granted for creating LDAP accounts. This file should always have 400 permissions so that nobody but the owner has read-only access. If the file does not exist one can use

`echo -n secret > ~/.pwf`

## Mail Groups
This tool can easily add email distribution groups in LDAP using an objectClass and group attribute from [pastfix-book.schema](https://github.com/variablenix/ldap-mail-schema/blob/master/postfix-book.schema). Simply give it a name and if the name is one that does not exist it will get added. Note that by default there are no group members added! Group members can be added using the `mailGroupMember` attribute.

### Adding/Removing LDAP Domains
This script currently supports a total of 8 domains and is easily customizable. One can simply add and remove any number of domains as needed. For example, domains are defined within the `domainlist` var. The following block of code can also be used to easily add more than 8 domains while making sure to substitute `n` with the actual domain number.
```
"${domainlist[n]}")
echo -e "creating mail account on $blue"${domainlist[n]}"$reset";;
```
Likewise, to remove domains in the event we don't need to use 8, we can easily remove domains from the 'domainlist' var and the relevant `n` block of code defined above.

_PRs welcome_
