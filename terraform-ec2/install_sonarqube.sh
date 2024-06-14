#!/bin/bash

# Update and upgrade system
sudo apt update
sudo apt upgrade -y



# Update and install dependencies
sudo apt update
sudo apt install -y openjdk-11-jre

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins

# Install Docker
sudo apt install -y docker.io
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

# Install Java
sudo apt install -y openjdk-17-jdk

# Install PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Configure PostgreSQL
sudo -i -u postgres psql <<EOF
CREATE USER ddsonar WITH ENCRYPTED PASSWORD '4Months0fR@in';
CREATE DATABASE ddsonarqube OWNER ddsonar;
GRANT ALL PRIVILEGES ON DATABASE ddsonarqube TO ddsonar;
EOF

# Install SonarQube
sudo apt install -y unzip
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.0.0.68432.zip
sudo unzip sonarqube-10.0.0.68432.zip
sudo mv sonarqube-10.0.0.68432 sonarqube
sudo mv sonarqube /opt/

# Configure SonarQube
sudo groupadd ddsonar
sudo useradd -d /opt/sonarqube -g ddsonar ddsonar
sudo chown ddsonar:ddsonar /opt/sonarqube -R

# Update sonar.properties file
sudo bash -c 'cat <<EOF >> /opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=ddsonar
sonar.jdbc.password=4Months0fR@in
sonar.jdbc.url=jdbc:postgresql://localhost:5432/ddsonarqube
EOF'

# Update sonar.sh file to add RUN_AS_USER
sudo sed -i 's/#RUN_AS_USER=/RUN_AS_USER=ddsonar/' /opt/sonarqube/bin/linux-x86-64/sonar.sh

# Create systemd service file for SonarQube
sudo bash -c 'cat <<EOF > /etc/systemd/system/sonar.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=ddsonar
Group=ddsonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF'

# Enable and start SonarQube service
sudo systemctl enable sonar
sudo systemctl start sonar

# Update system configuration
sudo bash -c 'cat <<EOF >> /etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
EOF'

# Apply the changes
sudo sysctl -p

# Update limits configuration
sudo bash -c 'cat <<EOF >> /etc/security/limits.conf
*    soft    nofile  65536
*    hard    nofile  65536
*    soft    nproc   4096
*    hard    nproc   4096
EOF'

# Reload systemd to apply changes
sudo systemctl daemon-reload
