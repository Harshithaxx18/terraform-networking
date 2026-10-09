
variable "project_id" {
  description = "Project identifier used to name and tag resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the pre-created VPC."
  type        = string
}

variable "public_instance_id" {
  description = "ID of the pre-created public EC2 instance."
  type        = string
}

variable "private_instance_id" {
  description = "ID of the pre-created private EC2 instance."
  type        = string
}

variable "allowed_ip_range" {
  description = "List of IPv4 CIDR ranges allowed to access the public infrastructure."
  type        = list(string)
}