variable "base_region" {
  description = "The base region to use for the provider"
  type        = string

  default = "ap-southeast-6"
}

variable "prefix" {
  description = "The prefix to use for resource names"
  type        = string

  default = "insurance"
}

variable "environment" {
  description = "The environment name"
  type        = string

  default = "shared"
}

variable "tags" {
  description = "The tags to apply to all resources"
  type        = map(string)

  default = {
    Workload    = "Insurance"
    Version     = "1.0.0"
    Environment = "shared"
  }
}