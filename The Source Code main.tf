# ==============================================================================
# ARCHITECTURE: ISO/IEC 27001 Compliant Isolated Perimeter Baseline
# COMPLIANCE MAPPING: Annex A.10 (Cryptographic controls), A.12 (Operations security), A.13 (Communications security)
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "production"
}

# ------------------------------------------------------------------------------
# 1. ISO 27001 Annex A.10: Enforced Cryptographic Key Management (KMS)
# ------------------------------------------------------------------------------
resource "aws_kms_key" "iso_encryption_key" {
  description             = "ISO 27001 Enforced Master Key for Production Storage Plane"
  deletion_window_in_days = 30
  enable_key_rotation     = true # Crucial ISO control

  tags = {
    Name              = "${var.environment}-iso27001-kms"
    Compliance_Control = "ISO_27001_A_10_1"
  }
}

# ------------------------------------------------------------------------------
# 2. ISO 27001 Annex A.13: Network Segment Isolation (VPC Multi-Tier)
# ------------------------------------------------------------------------------
resource "aws_vpc" "secure_perimeter" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name               = "${var.environment}-iso27001-vpc"
    Security_Boundary = "Strict_Isolate"
  }
}

# Explicitly strip and deny all default security group traffic (Security Best Practice)
resource "aws_default_security_group" "default_deny" {
  vpc_id = aws_vpc.secure_perimeter.id
  tags = {
    Name = "default-deny-all-ingress-egress"
  }
}

# Isolated Data Subnets (No route to Internet Gateway or NAT)
resource "aws_subnet" "isolated_data_az1" {
  vpc_id            = aws_vpc.secure_perimeter.id
  cidr_block        = "10.100.30.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name       = "${var.environment}-isolated-data-az1"
    Data_Class = "Highly_Confidential"
  }
}

# ------------------------------------------------------------------------------
# 3. ISO 27001 Annex A.12.4: Immutable Event Logging (VPC Flow Logs to CloudWatch)
# ------------------------------------------------------------------------------
resource "aws_flow_log" "vpc_traffic_audit" {
  iam_role_arn    = aws_iam_role.flow_logs_publisher.arn
  log_destination = aws_cloudwatch_log_group.audit_trail.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.secure_perimeter.id

  tags = {
    Name = "${var.environment}-vpc-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "audit_trail" {
  name              = "/aws/vpc-flow-logs/${var.environment}-iso27001"
  retention_in_days = 365 # 1 Year Audit Trail Retention
  kms_key_id        = aws_kms_key.iso_encryption_key.arn
}

resource "aws_iam_role" "flow_logs_publisher" {
  name = "${var.environment}-vpc-flow-logs-publisher-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_logs_permissions" {
  name = "${var.environment}-vpc-flow-logs-publisher-policy"
  role = aws_iam_role.flow_logs_publisher.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
