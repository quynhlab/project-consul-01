resource "ssh_resource" "example" {
  host         = "192.168.86.70"
  bastion_host = "192.168.86.70"
  user         = "smaniak"
  agent        = true

  file {
    content     = "echo '{\"hello\":\"world\"}' && exit 0"
    destination = "/home/alpine/test.sh"
    permissions = "0700"
  }

  commands = [
    "/home/alpine/test.sh",
  ]
}

output "result" {
  value = try(jsondecode(ssh_resource.example.result), {})
}