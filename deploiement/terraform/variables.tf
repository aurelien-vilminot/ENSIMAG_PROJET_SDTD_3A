data "external" "env" {
  program = ["${path.module}/scripts/env.sh"]
}

variable "region" {
    type    = string
    default = "europe-west9"
}

variable "number_workers" {
    type = number
    default = 2
}