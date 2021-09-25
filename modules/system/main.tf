resource "local_file" "dhcpcd_conf" {
  content = templatefile("${path.module}/dhcpcd.conf.tpl", var.dhcpcd)
  filename = var.dhcpcd_config_target_file
  file_permission = "664"
  directory_permission = "755"
}
