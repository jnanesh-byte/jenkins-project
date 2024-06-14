resource "aws_instance" "jenkins" {
  ami           = "ami-080e1f13689e07408"
  instance_type = "t2.xlarge"
  key_name      = "hardening"

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = "${file("install_sonarqube.sh")}"


  tags = {
    Name = "Jenkins"
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Allow SSH, HTTP, and custom ports access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Custom port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Custom port 9000"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

