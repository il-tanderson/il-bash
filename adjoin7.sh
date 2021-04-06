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
read -p "what is the primary DNS server: " dns1
read -p "what is the secondary DNS server: " dns2
read -p "what is the FQDN: " fqdn
read -p "what is the site/domain prefix: " prefix 
# Loops through possible options for hostname and chooses the correct DNS servers to set 
if [ "$dnsopt" = "$prefix" ]; then
    echo "nameserver $dns1" >> /etc/resolv.conf
    nmcli conn modify "$nic" ipv4.dns $dns1
    echo "nameserver $dns2" >> /etc/resolv.conf
    nmcli conn modify "$nic" +ipv4.dns $dns2
    echo "search $fqdn" >> /etc/resolv.conf
    nmcli conn modify "$nic" ipv4.dns-search $fqdn
else
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    nmcli conn modify "$nic" ipv4.dns 1.1.1.1
    echo "nameserver 8.8.8.8" >> /etc/resolv/conf
    nmcli conn modify "$nic" +ipv4.dns 8.8.8.8
fi
#Restart networking
systemctl restart NetworkManager
#Now we need to discover the realm
realm discover $fqdn
#Join the AD domain with user account with admin access
read -p "Enter your admin username: " admin
realm join --user=$admin $fqdn
#Add sudo access to the required groups
read -p "What is the exact Domain Admin group: " admin_group
echo "$admin_group   ALL=(ALL)       ALL">>/etc/sudoers
#Remove the FQDN requirement, remove the FQDN for user accounts, and restart sssd process
sed -i -e '/use_fully_qualified_names/s/True/False/' /etc/sssd/sssd.conf
sed -i -e '/fallback_homedir/s/%u@%d/%u/' /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf
systemctl restart sssd