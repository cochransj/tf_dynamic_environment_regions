locals {
  env    = split(".", terraform.workspace)[0]
  region = split(".", terraform.workspace)[1]

  default_tfsettings = {
    main_domain   = "${local.env}.foo.com"
    second_domain = "${local.region}.${local.env}.foo.com"
  }

  region_file          = "tfsettings/${local.env}/${local.region}.yaml"
  env_file             = "tfsettings/${local.env}/env.yaml"
  region_file_contents = fileexists(local.region_file) ? file(local.region_file) : "region_file: false"
  region_settings      = yamldecode(local.region_file_contents)
  env_file_contents    = fileexists(local.env_file) ? file(local.env_file) : "env_file: false"
  env_settings         = yamldecode(local.env_file_contents)
  tfsettings           = merge(local.default_tfsettings, local.region_settings, local.env_settings)
}

provider "aws" {
  version                 = "~> 2.0"
  region                  = local.region
  shared_credentials_file = "~/.aws/credentials"
  profile                 = local.env
}


output "region" {
  value = local.region
}

output "environment" {
  value = local.env
}

output "second_domain" {
  value = local.tfsettings.second_domain
}

output "instance_count" {
  value = local.tfsettings.instance_count
}

output "workspace" {
  value = terraform.workspace
}

output "RegionFile" {
  value = local.tfsettings.region_file
}

output "EnvFile" {
  value = local.tfsettings.env_file
}
