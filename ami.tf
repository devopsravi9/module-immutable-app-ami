resource "aws_ami_from_instance" "ami" {
  depends_on = [null_resource.ansible]
  name               = "${local.TAG_PREFIX}-${var.APP_VERSION}"
  source_instance_id = aws_instance.main.id
}