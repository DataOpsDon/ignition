variable "location" {
  description = "Azure region for naming"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "lz" {
  description = "Landing zone code"
  type        = string
}

variable "suffix" {
  description = "Suffix for naming"
  type        = string
}

variable "lz_short" {
  description = "Short landing zone code"
  type        = string
  default     = ""
}
