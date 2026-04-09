provider "aws" {
  region = "ap-south-1"
}

# ---------------- KEY PAIR ----------------
resource "aws_key_pair" "deployer" {
  key_name   = "devops-key"
  public_key = file("devops-key.pub")
}

# ---------------- SECURITY GROUP ----------------
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-workstation-sg"
  description = "Allow SSH"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Restrict to your IP in real-world
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- IAM ROLE ----------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach admin policy (for learning)
resource "aws_iam_role_policy_attachment" "ec2_admin" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-eks-profile"
  role = aws_iam_role.ec2_role.name
}

# ---------------- EC2 INSTANCE ----------------
resource "aws_instance" "workstation" {
  ami           = "ami-0a7cf821b91bcccbc" # Ubuntu 22.04 (ap-south-1)
  instance_type = "t2.micro"

  key_name = aws_key_pair.deployer.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  # ---------------- USER DATA (UBUNTU SETUP) ----------------
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Update system
              apt-get update -y
              apt-get upgrade -y

              # Install basic tools
              apt-get install -y curl unzip git

              # ---------------- AWS CLI ----------------
              apt-get install -y awscli

              # ---------------- kubectl ----------------
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              chmod +x kubectl
              mv kubectl /usr/local/bin/

              # ---------------- Docker ----------------
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              # ---------------- Verification logs ----------------
              aws --version
              kubectl version --client
              docker --version

              EOF

  tags = {
    Name = "devops-workstation"
  }
}