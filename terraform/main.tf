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
  tags = {
    Name = "ecs_instance_1"
  }
  
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
  tags = {
    Name = "ecs_instance_2"
  }

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

# S3 Bucket for Static Website Hosting (Frontend)
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "StaticFrontendBucket"
  }
}

resource "aws_s3_bucket_cors_configuration" "bucket_cors" {
  bucket = aws_s3_bucket.frontend_bucket.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

# Disable public access block settings for the S3 bucket to allow public access
resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls   = false
  block_public_policy = false
  restrict_public_buckets = false
  ignore_public_acls  = false
}

resource "aws_s3_bucket_ownership_controls" "ownership_controls_config_bucket" {
  bucket = aws_s3_bucket.frontend_bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.frontend_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "web_config" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Policy to allow public read on objects within the bucket
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
      }
    ]
  })
}

# Define the API Gateway
resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "HolaMundoAPI"
  description = "API Gateway for frontend-backend communication"
}

# Define the resource for Instance 1 ("/instance1")
resource "aws_api_gateway_resource" "instance_1_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "instance1"
}

# Define the GET method for Instance 1
resource "aws_api_gateway_method" "instance_1_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.instance_1_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "instance_1_method_response" {
    rest_api_id   = "${aws_api_gateway_rest_api.api_gateway.id}"
    resource_id   = "${aws_api_gateway_resource.instance_1_resource.id}"
    http_method   = "${aws_api_gateway_method.instance_1_get_method.http_method}"
    status_code   = "200"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = [ aws_api_gateway_method.instance_1_get_method ]
}

# Integrate API Gateway with Instance 1
resource "aws_api_gateway_integration" "instance_1_integration" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.instance_1_resource.id
  http_method = aws_api_gateway_method.instance_1_get_method.http_method
  type        = "HTTP"
  integration_http_method = "GET"
  uri         = "http://${aws_instance.ecs_instance_1.public_ip}/"
  
}

resource "aws_api_gateway_integration_response" "instance_1_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.instance_1_resource.id
  http_method = aws_api_gateway_method_response.instance_1_method_response.http_method
  status_code = aws_api_gateway_method_response.instance_1_method_response.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = "#set($inputRoot = $input.path('$'))\n$inputRoot" # This simply returns the raw body from the backend
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# Define the resource for Instance 1.5 ("/instance1_5")
resource "aws_api_gateway_resource" "instance_15_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "instance1_5"
}

# Define the GET method for Instance 1.5
resource "aws_api_gateway_method" "instance_15_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.instance_15_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "instance_15_method_response" {
    rest_api_id   = "${aws_api_gateway_rest_api.api_gateway.id}"
    resource_id   = "${aws_api_gateway_resource.instance_15_resource.id}"
    http_method   = "${aws_api_gateway_method.instance_15_get_method.http_method}"
    status_code   = "200"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = [ aws_api_gateway_method.instance_15_get_method ]
}

# Integrate API Gateway with Instance 1.5
resource "aws_api_gateway_integration" "instance_15_integration" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.instance_15_resource.id
  http_method = aws_api_gateway_method.instance_15_get_method.http_method
  type        = "HTTP"
  integration_http_method = "GET"
  uri         = "http://${aws_instance.ecs_instance_1.public_ip}:443/"
}

resource "aws_api_gateway_integration_response" "instance_15_integration_response" {
  depends_on = [ aws_api_gateway_resource.instance_15_resource ]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.instance_15_resource.id
  http_method = aws_api_gateway_method_response.instance_15_method_response.http_method
  status_code = aws_api_gateway_method_response.instance_15_method_response.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = "#set($inputRoot = $input.path('$'))\n$inputRoot" # This simply returns the raw body from the backend
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# Define the resource for Instance 2 ("/instance2")
resource "aws_api_gateway_resource" "instance_2_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "instance2"
}

# Define the GET method for Instance 2
resource "aws_api_gateway_method" "instance_2_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.instance_2_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "instance_2_method_response" {
    rest_api_id   = "${aws_api_gateway_rest_api.api_gateway.id}"
    resource_id   = "${aws_api_gateway_resource.instance_2_resource.id}"
    http_method   = "${aws_api_gateway_method.instance_2_get_method.http_method}"
    status_code   = "200"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = [ aws_api_gateway_method.instance_2_get_method ]
}

# Integrate API Gateway with Instance 2
resource "aws_api_gateway_integration" "instance_2_integration" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.instance_2_resource.id
  http_method = aws_api_gateway_method.instance_2_get_method.http_method
  type        = "HTTP"
  integration_http_method = "GET"
  uri         = "http://${aws_instance.ecs_instance_2.public_ip}/"
}

resource "aws_api_gateway_integration_response" "instance_2_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.instance_2_resource.id
  http_method = aws_api_gateway_method_response.instance_2_method_response.http_method
  status_code = aws_api_gateway_method_response.instance_2_method_response.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = "#set($inputRoot = $input.path('$'))\n$inputRoot" # This simply returns the raw body from the backend
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# Update deployment dependencies
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  depends_on = [
    aws_api_gateway_integration.instance_1_integration,
    aws_api_gateway_integration.instance_2_integration,
    aws_api_gateway_integration.instance_15_integration,
  ]
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  stage_name    = "stage"
}

# Outputs for EC2 public IPs and API Gateway URL
output "instance_1_public_ip" {
  value = aws_instance.ecs_instance_1.public_ip
}

output "instance_2_public_ip" {
  value = aws_instance.ecs_instance_2.public_ip
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}

