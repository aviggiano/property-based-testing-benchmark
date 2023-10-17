variable "docker_host" {
  # https://discuss.hashicorp.com/t/cannot-connect-to-docker-daemon/34122/9
  description = "Docker daemon socket address"
  default = "unix:///var/run/docker.sock"
}