resource "aws_security_group" "vpc_link_sg" {
  name        = "vpc-link-sg"
  description = "Security group for the VPC Link"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = "httpapi-alb-vpc-link"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_link_sg.id]
}


resource "aws_apigatewayv2_api" "http_api" {
  name          = "epam-http-api-${var.TF_VAR_env}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.http.arn # Use the ALB listener ARN
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.vpc_link.id
  integration_method = "ANY"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}" # Catch-all route for all paths]"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"

  # authorization_type = "JWT"
  # authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  #   depends_on = [
  #     aws_apigatewayv2_route.route,
  #     aws_apigatewayv2_integration.alb_integration
  #   ]
}

########


resource "aws_cognito_user_pool" "default_user_pool" {
  name = "epam-demo-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Ensure email verification via OTP
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = false
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "epam-demo-client"
  user_pool_id = aws_cognito_user_pool.default_user_pool.id


  generate_secret = false

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid"]
  allowed_oauth_flows_user_pool_client = true
  explicit_auth_flows                  = ["ALLOW_USER_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  callback_urls = ["${aws_apigatewayv2_stage.stage.invoke_url}hello"]

  supported_identity_providers = ["COGNITO"]
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  name            = "CognitoJWTAuth"
  api_id          = aws_apigatewayv2_api.http_api.id
  authorizer_type = "JWT"

  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.default_user_pool.id}"
  }
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain                = "epam-demo-web-app" # must be globally unique
  user_pool_id          = aws_cognito_user_pool.default_user_pool.id
  managed_login_version = 1
}


resource "aws_cognito_user_pool_ui_customization" "example" {
  css = ".label-customizable {font-weight: 400;}"
  #   image_file = filebase64("logo.png")

  # Refer to the aws_cognito_user_pool_domain resource's
  # user_pool_id attribute to ensure it is in an 'Active' state
  user_pool_id = aws_cognito_user_pool_domain.domain.user_pool_id
}