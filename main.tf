variable "region" {}

output "base_ami_id" {
    value = "${lookup(var.digit_base_ami_id, var.region)}"
}

output "pipeline_ami_id" {
    value = "${lookup(var.visii_pipeline_ami_id, var.region)}"
}
