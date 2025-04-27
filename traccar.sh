#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define MySQL root password and Traccar database credentials
MYSQL_ROOT_PASSWORD='!Traccar321'
TRACCAR_DB='traccar_db'
TRACCAR_USER='traccar1'
TRACCAR_PASSWORD='!Traccar321'

# Update and upgrade system packages
apt-get update && apt-get upgrade -y

# Install necessary packages
apt-get install -y wget unzip default-jre mysql-server net-tools ufw

# Secure MySQL installation
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"

# Create Traccar database and user
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE ${TRACCAR_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER '${TRACCAR_USER}'@'localhost' IDENTIFIED BY '${TRACCAR_PASSWORD}';"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${TRACCAR_DB}.* TO '${TRACCAR_USER}'@'localhost'; FLUSH PRIVILEGES;"

# Download and install Traccar
wget https://www.traccar.org/download/traccar-linux-64-latest.zip
unzip traccar-linux-64-latest.zip
chmod +x traccar.run
./traccar.run

# Configure Traccar to use MySQL and enable specific protocols
cat > /opt/traccar/conf/traccar.xml << EOF
<?xml version='1.0' encoding='UTF-8'?>

<!DOCTYPE properties SYSTEM 'http://java.sun.com/dtd/properties.dtd'>

<properties>
    <entry key='config.default'>./conf/default.xml</entry>
    <entry key='web.port'>8082</entry>
    <entry key='database.driver'>com.mysql.cj.jdbc.Driver</entry>
    <entry key='database.url'>jdbc:mysql://localhost:3306/${TRACCAR_DB}?serverTimezone=UTC&amp;allowPublicKeyRetrieval=true&amp;useSSL=false&amp;allowMultiQueries=true&amp;autoReconnect=true&amp;useUnicode=yes&amp;characterEncoding=UTF-8&amp;sessionVariables=sql_mode=''</entry>
    <entry key='database.user'>${TRACCAR_USER}</entry>
    <entry key='database.password'>${TRACCAR_PASSWORD}</entry>
    <entry key='protocols.enable'>osmand,gt06</entry>
</properties>
EOF

# Start Traccar service
systemctl start traccar
systemctl enable traccar

# Configure UFW firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 8082/tcp  # Traccar Web Interface
ufw allow 5023/tcp  # GT06 Protocol Port
ufw --force enable

# Display access information
clear
echo "Traccar installation completed successfully!"
echo "Access the Traccar web interface at: http://$(hostname -I | awk '{print $1}'):8082"
