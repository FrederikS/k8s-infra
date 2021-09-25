variable "dhcpcd" {
  type = map(string)
  description = "config values for dhcpcd"
  default = {
    interface = "wlan0"
    static_ip = "192.168.2.107/24"
    router_ip = "192.168.2.1"
    name_servers = "192.168.2.1 8.8.8.8 fe80::1"
  }
}

variable "dhcpcd_config_target_file" {
  type = string
  default = "/etc/dhcpcd.conf"
}
