# Specify AWS provider version and region
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Create an ECS cluster using EC2
resource "aws_ecs_cluster" "node_app_cluster" {
  name = "HolaMundoCloud-cluster"
}

# IAM role for the ECS task execution
resource "aws_iam_role" "ecs_role" {
  name = "ecs_role_HolaMundoCloud"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ecs_policy_attachment" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS instance profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile_HolaMundoCloud"
  role = aws_iam_role.ecs_instance_role.name
}

# IAM role for ECS EC2 instances
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecsInstanceRole_HolaMundoCloud"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

# Create the first EC2 instance
resource "aws_instance" "ecs_instance_1" {
  ami                    = "ami-0e593d2b811299b15" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  key_name               = var.aws_key_name
  iam_instance_profile   = aws_iam_instance_profile.ecs_instance_profile.name
  security_groups        = [aws_security_group.ecs_sg.id]
  subnet_id              = aws_subnet.public_a.id
  associate_public_ip_address = true

  user_data = base64encode(<<-EOF
                #!/bin/bash
                # Update the instance
                sudo yum update -y

                # Install Docker
                sudo amazon-linux-extras install docker -y
                sudo service docker start
                sudo usermod -a -G docker ec2-user

                # Install Git
                sudo yum install -y git

                # Install Docker Compose
                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

                # Clone your Node.js app from the Git repository
                cd /home/ec2-user
                git clone https://github.com/Fabrizzio-Esquivel-UNAS/HolaMundoCloud_APIGatewayEdition.git nodeapp
                cd nodeapp

                # Run the services with Docker Compose
                sudo docker-compose up --build -d
                EOF
  )
}

# Create the second EC2 instance
resource "aws_instance" "ecs_instance_2" {
  ami                    = "ami-0e593d2b811299b15" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  key_name               = var.aws_key_name
  iam_instance_profile   = aws_iam_instance_profile.ecs_instance_profile.name
  security_groups        = [aws_security_group.ecs_sg.id]
  subnet_id              = aws_subnet.public_b.id
  associate_public_ip_address = true

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Update the instance
              sudo yum update -y

              # Install Docker
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user

              # Install Git
              sudo yum install -y git

              # Clone your Node.js app from the Git repository (replace with your repo)
              cd /home/ec2-user
              git clone https://github.com/Fabrizzio-Esquivel-UNAS/HolaMundoCloud_APIGatewayEdition.git nodeapp
              cd nodeapp/charlie-service

              # Build the Docker image
              sudo docker build -t nodeapp .

              # Run the Docker container
              sudo docker run -d -p 80:3000 nodeapp
              EOF
  )
}