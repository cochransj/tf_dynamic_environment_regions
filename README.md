# Dynamic Variables & Provider In Terraform

Often organizations will split their production environment into a different accounts for operational reasons. Additionally, some organizations will find that they want to segment the terraform state between regions, while still applying from the same code base.  

This repository is an example of how to use terraform workspaces to implement the same resource declarations across multiple aws accounts across multiple regions. It also shows how to have a data driven approach to feeding region and environment specific data into these resources.


The expectation for this example is that workspaces will have a `<env>`.`<region ID>` naming convention.  In the case of having a `prod`, and `int` environments it would look like this:
```
$ terraform workspace list
  default
  int.us-east-1
  int.us-east-2
  prod.us-east-1
  prod.us-east-2
* prod.us-west-1
  prod.us-west-2
```

Utilizing the `terraform.workspace` value, we can then split our environment and region out using the `split()` function.  These two values will be the basis of how we derive values specific to the environment and region from the tfsettings folder, and configure our AWS terraform provider to point to the appropriate account.  

We take an override/default approach by also setting a `default_tfsettings` value in our locals block of the main.tf file.  For our example we are creating domain names that are specific to the region and environment.   This is something we can leverage when creating ec2 instances, load balancers, or anything else that will require dns configurations.

We then pull in two yaml files located in subdirectories within the tfsettings directory. The subdirectories are split into the different environments that will be applied to, and within those subdirectories, there will be an `env.yaml` file for values that are true for all of the environment, and a file for each region to hold values specific to the regions for that environment.  

At the end of this, we create a `local.tfsettings` value that will merge all of these values.  This allows the `default_tfsettings` to provide default values, and be overridden by the yaml files pulled in.  

In the AWS provider block we are using `local.region` and `local.env` to dynamically pull credentials from profiles created by the aws cli tool.  These can be generated by using the commands `aws configure --profile int` and `aws configure --profile prod` respectively.  This will prompt you for your aws secret key values needed to configure the `~/.aws.credentials` file with profiles that the terraform aws provider will leverage.

This allows a great deal of flexibility in configuring resources specific to a combination of region and environment. We demonstrate this with the following exercise.

First we need to create the proper credentials in the required profiles for the aws cli tool.  Run the following.

```
aws configure --profile int
```
```
aws configure --profile prod
```

When the key prompts come up, you can put junk data in.  Since this module is using outputs to demonstrate this functionality rather than resources this value does not need to be valid.  When you start feeding these values into resource declarations this will need to be valid.

We also need to configure the workspaces.   For this example we only need two of those, but as you add files to the tfsettings directory this can scale.  

```
terraform workspace new int.us-east-1 && terraform workspace new prod.us-east-1
```

Initialize the workspace

```
terraform init
```

Apply the `prod.us-east-1` workspace

```
$ terraform apply

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

EnvFile = true
RegionFile = true
environment = prod
instance_count = 7
region = us-east-1
second_domain = foo.example.com
workspace = prod.us-east-1
```

Here we can see that we have output showing that `instance_count` is pulling it's value from `tfsettings/prod/us-east-1.yaml` file, and is overriding the domain information by having `tfsettings/prod/env.yaml` contain values for `main_domain` and `second_domain`

If we now switch to the `int.us-east-1` workspace and apply
```
terraform workspace select int.us-east-1
```
```
$ terraform apply

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

EnvFile = true
RegionFile = true
environment = int
instance_count = 4
region = us-east-1
second_domain = us-east-1.int.foo.com
workspace = int.us-east-1
```

Now we can see that `instance_count` is a different value provided by  `tfsettings/int/us-east-1.yaml`. This also shows that we are no longer using overridden values for the domain name. Now the default_tfsettings interpolation since the `main_domain` and `second_domain` values are not set in our `tfsettings/prod/` directory.  This works regardless of the `env.yaml` file's existence.  We also have the ability to leverage `local.tfsettings.region_file` and `local.tfsettings.env_file` later in our module for defensive concepts.  
