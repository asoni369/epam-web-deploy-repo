resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Effect = "Allow"
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}       

resource "aws_lambda_function" "lambda_authorizer" {
  function_name = "http-api-lambda-authorizer"
  handler       = "authorizer.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "lambda.zip"

  environment {
    variables = {
      COGNITO_POOL_ID = aws_cognito_user_pool.default_user_pool.id,
      AWS_REGION      = var.aws_region,
      COGNITO_CLIENT_ID = aws_cognito_user_pool_client.client.id,
    }
  }
}