# Create an IAM policy for Lambda function permissions
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-ec2-launch-policy"
  description = "IAM policy for Lambda to launch EC2 instances"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ 
                "ec2:RunInstances",
                "ec2:DescribeInstances",
                "ec2:TerminateInstances",
                "ec2:CreateTags",
                "s3:GetObject",
                "s3:ListBucket",
                "sns:Publish"
                ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_ec2_launch_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
# Attach the Lambda function policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}
resource "aws_iam_role_policy_attachment" "lambda_logs_policy_attachment_" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}
resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
   policy_arn = "arn:aws:iam::631231558475:policy/s3tocalllambda"
  role       = aws_iam_role.lambda_role.name
}

#jenkins server to get s3 full access
resource "aws_iam_role" "s3full_role" {
  name = "s3full_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3full_policy" {
  name        = "s3full_policy"
  description = "Policy to allow full access to S3"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "s3:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3full_policy_attachment" {
  role       = aws_iam_role.s3full_role.name
  policy_arn = aws_iam_policy.s3full_policy.arn
}

resource "aws_iam_instance_profile" "s3full_instance_profile" {
  name = "s3full_instance_profile"
  role = aws_iam_role.s3full_role.name
}
