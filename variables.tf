variable "TF_VAR_env" {
  description = "The environment for the deployment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "ecr_image_url" {
  description = "The ECR image URL for the web server"
  type        = string
  default     = "445567099272.dkr.ecr.ap-southeast-2.amazonaws.com/epam/web-server-repo:latest"
}

variable "aws_region" {
  description = "The AWS region where resources will be deployed"
  type        = string
  default     = "ap-southeast-2"

}