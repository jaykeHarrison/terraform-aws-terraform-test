terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

resource "random_pet" "random_prefix" {
  length = 4
}

output "random_prefix" {
    value = random_pet.random_prefix.id
}