package services

type ServiceDiscovery interface {
	RegisterEndpoints()
	LongPolling()
	RunServer(port string)
}
