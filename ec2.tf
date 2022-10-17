resource "aws_instance" "main" {
  ami           = data.aws_ami.main.image_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.main.id]

  tags = {
    Name = local.TAG_PREFIX
  }
}

resource "null_resource" "file" {
  triggers = {
    abc = timestamp()
  }

  provisioner "file" {
    connection {
      user     = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_PASS"]
      host     = aws_instance.main.private_ip
    }
  source      = "${var.COMPONENT}-${var.APP_VERSION}.zip"
  destination = "/tmp/${var.COMPONENT}.zip"
  }
}

resource "null_resource" "ansible" {
  triggers = {
    abc = timestamp()
  }

  provisioner "remote-exec" {
    depends_on = [null_resource.file]
    connection {
      user     = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_PASS"]
      host     = aws_instance.main.private_ip
    }
    inline = [
      "git clone https://github.com/devopsravi9/roboshop-ansible.git",
      "cd /home/centos/roboshop-ansible/ansible",
      "git pull",
      "ansible-playbook robo.yml -e HOST=localhost -e ROLE=${var.COMPONENT} -e ENV=ENV -e DOCDB_ENDPOINT=DOCDB_ENDPOINT -e REDDIS_ENDPOINT=REDDIS_ENDPOINT  -e MYSQL_ENDPOINT=MYSQL_ENDPOINT",
    ]
  }
}

