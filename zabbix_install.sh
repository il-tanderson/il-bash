#Add zabbix agent repo and install zabbix agent
yum install https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-agent-5.0.3-1.el7.x86_64.rpm
yum install zabbix-agent
# Read in IP of zabbix server
read -p "What is the IP of the Zabbix Server: " zabbix
# Add Zabbix IP in conf file and add to firewall
sed -i -e '/Server=/s/127.0.0.1/$zabbix/' /etc/zabbix/zabbix_agentd.conf
sed -i -e '/ServerActive=/s/127.0.0.1/$zabbix/' /etc/zabbix/zabbix_agentd.conf
firewall-cmd --add-port=10050/tcp --permanent 
firewall-cmd --reload
# Start and Enable service
systemctl start zabbix-agent
systemctl enable zabbix-agent