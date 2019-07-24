module "under_test" {
  source = "../.."

  zone_name = "example.com"
  recordsets = [
    {
      name    = "foo"
      type    = "A"
      ttl     = 300
      records = ["10.1.2.1", "10.1.2.2"]
    },
    {
      name    = "bar"
      type    = "A"
      ttl     = 300
      records = ["10.1.2.3"]
    },
    {
      name    = "bar"
      type    = "AAAA"
      ttl     = 300
      records = ["::1"]
    },
    {
      name    = "mail"
      type    = "CNAME"
      ttl     = 300
      records = ["foo", "bar"]
    },
    {
      name    = ""
      type    = "NS"
      ttl     = 300
      records = ["foo", "bar"]
    },
  ]
}

provider "dns" {
  update {
    server        = "${docker_container.bind.ports[0].ip}:${docker_container.bind.ports[0].external}"
    key_name      = "example.com."
    key_algorithm = "hmac-md5"
    key_secret    = "c3VwZXJzZWNyZXQ="
  }
}

resource "docker_container" "bind" {
  name  = "terraform-dns-recordsets-test-simple"
  image = docker_image.bind.latest

  ports {
    internal = 53
    external = 55354
    ip       = "127.0.0.1"
    protocol = "udp"
  }

  env = [
    "BIND_DOMAIN_FORWARD=example.com.",
    "BIND_DOMAIN_REVERSE=1.168.192.in-addr.arpa.",
    "BIND_KEY_NAME=example.com.",
    "BIND_KEY_ALGORITHM=hmac-md5",
    "BIND_KEY_SECRET=c3VwZXJzZWNyZXQ=",
  ]
}

resource "docker_image" "bind" {
  name = "drebes/bind:latest"
}

