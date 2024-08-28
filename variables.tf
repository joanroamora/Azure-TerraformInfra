variable "subscription_id" {
  description = "Subscription Id Azure"
  type        = string
}

variable "tenant_id" {
  description = "Tenant Id azure."
  type        = string
}

variable "location" {
  description = "location of the project."
  type        = string
}

variable "resourceGroup" {
  description = "resource group of your project."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/20"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet."
  type        = string
  default     = "10.0.0.0/22"
}

variable "private_subnet1_cidr" {
  description = "The CIDR block for the first private subnet."
  type        = string
  default     = "10.0.4.0/22"
}

variable "private_subnet2_cidr" {
  description = "The CIDR block for the second private subnet."
  type        = string
  default     = "10.0.8.0/22"
}

variable "vm_size" {
  description = "The size of the virtual machines."
  type        = string
  default     = "Standard_B1ls" # One of the most economical sizes in Azure
}

variable "vm_count" {
  description = "Number of frontend virtual machines."
  type        = number
  default     = 2
}

variable "admin_username" {
  description = "Admin username for the virtual machines."
  type        = string
  default     = "colombianTestUser"
}

variable "admin_password" {
  description = "Admin password for the virtual machines."
  type        = string
  sensitive   = true
  default     = "passwordTestUser89*"
}

variable "frontend_lb_public_ip_name" {
  description = "Name of the public IP for the frontend load balancer."
  type        = string
  default     = "frontend-lb-public-ip"
}

variable "frontend_lb_name" {
  description = "Name of the frontend load balancer."
  type        = string
  default     = "frontend-lb"
}

variable "frontend_security_group_name" {
  description = "Name of the security group for the frontend VMs."
  type        = string
  default     = "frontend-sg"
}

variable "backend_vm_size" {
  description = "The size of the backend virtual machine."
  type        = string
  default     = "Standard_B1ls"  # A cost-effective size, similar to frontend
}

variable "backend_security_group_name" {
  description = "The name of the security group for the backend VM."
  type        = string
  default     = "backend-sg"
}

variable "backend_admin_username" {
  description = "Admin username for the backend VM."
  type        = string
  default     = "colombianTestUser"
}

variable "backend_admin_password" {
  description = "Admin password for the backend VM."
  type        = string
  sensitive   = true
  default     = "passwordTestUser89*"
}

variable "sql_server_name" {
  description = "The name of the SQL Server."
  type        = string
  default     = "unique-sqlserver-name-123"  
}

variable "sql_admin_username" {
  description = "Admin username for the SQL server."
  type        = string
  default     = "colombianTestUser"
}

variable "sql_admin_password" {
  description = "Admin password for the SQL server."
  type        = string
  sensitive   = true
  default     = "passwordTestUser89*"
}

variable "sql_database_name" {
  description = "The name of the SQL database."
  type        = string
  default     = "mydatabase"
}

variable "sql_security_group_name" {
  description = "The name of the security group for the SQL server."
  type        = string
  default     = "sql-sg"
}

#SECOND AVAILABILITY REGION

variable "secondary_location" {
  description = "The secondary Azure region for redundancy."
  type        = string
}
