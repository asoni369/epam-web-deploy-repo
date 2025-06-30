output "api_gw_url" {
  description = "The URL of the API Gateway"
  value       = aws_apigatewayv2_stage.stage.invoke_url
}

output "alb_dns_name" {
  description = "The private DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}
