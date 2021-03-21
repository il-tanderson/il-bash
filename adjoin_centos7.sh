#!/bin/bash
#First we need to set the Hostname
read -p "what is the hostname of the server: " hostname
hostnamectl set-hostname $hostname
echo $hostname >> /etc/hostname
#First run upgrades on existing packages to make sure everything is patched
yum -y update
#Next install the required AD packages
yum -y install realmd sssd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation
nic=$(nmcli -g name con|awk 'NR==1{print $1}')
#Now we want to update the DNS
sed -i '/nameserver/d' /etc/resolv.conf # clears the existing nameservers for the config
#creates a var to store the location/vpc portion of hostname
dnsopt=$(echo $hostname | awk -F- '{print $1}')
# Loops through possible options for hostname and chooses the correct DNS servers to set 
if [ "$dnsopt" = "*Domain Prefix Here*" ]; then
    echo "nameserver *DNS Server1 Here*" >> /etc/resolv.conf
    nmcli conn modify "$nic" ipv4.dns "*DNS Server1 Here*"
    echo "nameserver *DNS Server2 Here*" >> /etc/resolv.conf
    nmcli conn modify "$nic" +ipv4.dns "*DNS Server2 Here*"
    echo "search *FQDN Here*" >> /etc/resolv.conf
    nmcli conn modify "$nic" ipv4.dns-search *FQDN Here*
else
    echo "nameserver *Public DNS Server1 here" >> /etc/resolv.conf
    nmcli conn modify "$nic" ipv4.dns "*Public DNS Server1 here*"
    echo "nameserver *Public DNS Server2 here" >> /etc/resolv/conf
    nmcli conn modify "$nic" +ipv4.dns "*Public DNS Server2 here*"
fi
#Restart networking
systemctl restart NetworkManager
#Now we need to discover the realm
realm discover *FQDN Here*
#Join the AD domain with user account with admin access
read -p "Enter your admin username: " admin
realm join --user=$admin *FQDN Here*
#Add sudo access to the required groups
echo "*Admin AD Group Here*   ALL=(ALL)       ALL">>/etc/sudoers
#Remove the FQDN requirement, remove the FQDN for user accounts, and restart sssd process
sed -i -e '/use_fully_qualified_names/s/True/False/' /etc/sssd/sssd.conf
sed -i -e '/fallback_homedir/s/%u@%d/%u/' /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf
systemctl restart sssd
