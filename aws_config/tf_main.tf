provider "aws" {
  region = "ca-central-1"
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "LambdaExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for Lambda Execution
resource "aws_iam_policy" "lambda_policy" {
  name = "LambdaPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress",
          "config:PutEvaluations",
          "config:DescribeConfigRules",
          "config:DescribeConfigRuleEvaluationStatus",
          "config:GetComplianceDetailsByConfigRule",
          "config:ListDiscoveredResources"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach IAM Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# IAM Role for SSM Automation Execution
resource "aws_iam_role" "ssm_automation_role" {
  name = "SSM-Automation-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ssm.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for SSM Automation Execution
resource "aws_iam_policy" "ssm_automation_policy" {
  name = "SSM-Automation-Policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:ExecuteAutomation",
          "lambda:InvokeFunction",
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress",
          "config:PutEvaluations"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach IAM Policy to SSM Role
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ssm_automation_role.name
  policy_arn = aws_iam_policy.ssm_automation_policy.arn
}

# AWS Config Rule
resource "aws_config_config_rule" "tf_security_groups_open_to_world" {
  name = "tf_security_groups_open_to_world"

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = "<<ARN FOR CheckUnrestrictedSecurityGroups LAMBDA GOES HERE >>"
    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }
}

# SSM Automation Document
resource "aws_ssm_document" "tf_removesecuritygrouprule" {
  name          = "tf_removesecuritygrouprule"
  document_type = "Automation"

  content = jsonencode({
    schemaVersion = "0.3",
    description   = "Removes the security group rule that allows traffic from 0.0.0.0/0.",
    assumeRole    = "${aws_iam_role.ssm_automation_role.arn}",
    parameters = {
      SecurityGroupId = {
        type        = "String",
        description = "The ID of the security group to remediate."
      }
    },
    mainSteps = [
      {
        name   = "InvokeLambdaFunction",
        action = "aws:invokeLambdaFunction",
        inputs = {
          FunctionName = "<<ARN FOR DeleteSecurityGroupUnrestrictedRules LAMBDA GOES HERE>>",
          Payload      = jsonencode({ "SecurityGroupId" : "{{ SecurityGroupId }}" })
        }
      }
    ]
  })
}

# AWS Config Remediation Configuration
resource "aws_config_remediation_configuration" "tf_remediation_config" {
  config_rule_name = aws_config_config_rule.tf_security_groups_open_to_world.name
  target_id        = aws_ssm_document.tf_removesecuritygrouprule.name
  target_type      = "SSM_DOCUMENT"
  resource_type    = "AWS::EC2::SecurityGroup"

  parameter {
    name           = "SecurityGroupId"
    resource_value = "RESOURCE_ID"
  }

  automatic = false
}
