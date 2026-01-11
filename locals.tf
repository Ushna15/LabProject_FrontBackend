locals {
  # This fetches your IP and removes the newline character
  my_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

# The data source to fetch the IP
data "http" "my_ip" {
  url = "https://icanhazip.com"
}