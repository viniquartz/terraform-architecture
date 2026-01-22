variable "name" {
  description = "DNS Zone name (e.g., example.com)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "a_records" {
  description = "Map of A records"
  type = map(object({
    ttl     = number
    records = list(string)
  }))
  default = {}
}

variable "cname_records" {
  description = "Map of CNAME records"
  type = map(object({
    ttl    = number
    record = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
