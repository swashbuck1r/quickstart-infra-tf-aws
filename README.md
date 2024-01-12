The infrastructure is managed with `terragrunt`

== Applying changes

You will need to ensure you have the following toolchains installed:

* Terragrunt
* Terraform
* AWS CLI


To automatically apply any changes, run:

[source,shell]
----
$ terragrunt run-all apply  --terragrunt-non-interactive
----


Check the plan across all definitions

[source,shell]
----
$ terragrunt run-all plan
----