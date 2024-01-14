variable "application_name" {
  type = string
  description = "The name of application"
  default = "pelada"
}

variable "rg_name" {
  type = string
  description = "The name of default resource group"
  default = "rg-pelada-app"
}

variable "rg_location" {
  type = string
  description = "The location of default resource group"
  default = "West US"
}

variable "rg_tags" {
  type = map(string)
  default = {
    rg-pelada-app: "pelada"
    }
}