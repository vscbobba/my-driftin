# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "bobbascloud-workspace"  # Update with your desired bucket name
}

# Configure S3 event notification to trigger Lambda function
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.my_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_trigger_lambda.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

# Create a CloudWatch Logs group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/WORKSPACE"  # Update with your desired log group name
  retention_in_days = 14  # Update with your desired retention period
}

# Create an AWS Lambda function
resource "aws_lambda_function" "s3_trigger_lambda" {
  filename      = "lambda_function.zip"  # Update with the path to your Lambda function code
  function_name = "WORKSPACE"  # Update with your desired Lambda function name
  role          = data.terraform_remote_state.platform.outputs.lambda_role1
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  source_code_hash = filebase64sha256("lambda_function.zip")
  timeout       = 60  # Update with your desired timeout
  memory_size   = 128  # Update with your desired memory size

  tracing_config {
    mode = "Active"
  }

  # Link Lambda function to CloudWatch Logs
  depends_on = [aws_cloudwatch_log_group.lambda_logs]

}

resource "aws_lambda_permission" "allow_s3_to_invoke_1" {
    statement_id  = "AllowS3Invoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.s3_trigger_lambda.function_name
    principal = "s3.amazonaws.com"
    source_arn = aws_s3_bucket.my_bucket.arn
    source_account = 631231558475
}