variable "ami_gpu" {
  description = "ID of AMI to use for the instance"
  type        = string
  default     = null
}

variable "ami_cpu" {
  description = "ID of AMI to use for the instance"
  type        = string
  default     = null
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = null
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  default     = null
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  default     = null
}

variable "cpu_instance_type" {
  description = "Instance type"
  type        = string
  default     = "m5.xlarge"
}

variable "gpu_instance_type" {
  description = "Instance type"
  type        = string
  default     = "g5.xlarge"
}