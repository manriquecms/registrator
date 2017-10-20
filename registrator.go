package main

import (
	"github.com/stratio/registrator/consul"
	"github.com/stratio/registrator/services"
)

///////
// MAIN
///////
func main() {
	var servicediscovery services.ServiceDiscovery = consul.Consul{}
	servicediscovery.RegisterEndpoints()
	servicediscovery.LongPolling()
	servicediscovery.RunServer(":12000")
}
