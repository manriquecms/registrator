package consul

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/stratio/registrator/util"
	"io/ioutil"
	"log"
	"net/http"
	"strings"
)

/////////
// CONSTS
/////////
const (
	RaftMembersURL         = "http://consul.service.paas.labs.stratio.com:8500/v1/operator/raft/configuration"
	RegisterServiceURL     = "http://%s.node.paas.labs.stratio.com:8500/v1/agent/service/register"
	DeregisterServiceURL   = "http://%s.node.paas.labs.stratio.com:8500/v1/agent/service/deregister/%s"
	NodeHealthURL          = "http://consul.service.paas.labs.stratio.com:8500/v1/health/node/%s"
	AgentMembersURL        = "http://consul.service.paas.labs.stratio.com:8500/v1/agent/members"
	CatalogNodesURL        = "http://consul.service.paas.labs.stratio.com:8500/v1/catalog/nodes"
	CatalogNodesOrderedURL = "http://consul.service.paas.labs.stratio.com:8500/v1/catalog/nodes?near=%s"
	ServiceHealthURL       = "http://consul.service.paas.labs.stratio.com:8500/v1/health/service/%s"
)

//////////
// STRUCTS
//////////
type Consul struct {
}

type StatusResponse struct {
	Status string `json:"Status"`
}

type CatalogNode struct {
	Node            string        `json:"Node"`
	Address         string        `json:"Address"`
	TaggedAddresses TaggedAddress `json:"TaggedAddresses"`
}

type TaggedAddress struct {
	Lan string `json:"lan"`
	Wan string `json:"wan"`
}

type AgentMember struct {
	Name   string `json:"Name"`
	Addr   string `json:"Addr"`
	Status int    `json:"Status"`
}

type HealthNode struct {
	Node    string `json:"Node"`
	CheckID string `json:CheckID`
	Status  string `json:Status`
}

type Raft struct {
	Index   int      `json:"Index"`
	Servers []Server `json:Servers`
}
type Server struct {
	ID      string `json:"ID"`
	Node    string `json:"Node"`
	Address string `json:"Address"`
	Leader  bool   `json:"Leader"`
	Voter   bool   `json:"Voter"`
}

////////////
// FUNCTIONS
////////////
func getLeader() string {
	resp := util.GetMethod(RaftMembersURL, bytes.NewBuffer([]byte{}))
	body, err := ioutil.ReadAll(resp.Body)

	var leader string

	if err != nil {
		log.Printf("Error reading body: %v", err)
	} else {
		var raft Raft
		if err := json.Unmarshal(body, &raft); err != nil {
			panic(err)
		}

		for i := 0; i < len(raft.Servers); i++ {
			if raft.Servers[i].Leader {
				leader = raft.Servers[i].Node
				i = len(raft.Servers)
			}
		}
	}
	return leader
}

func getServers() []string {
	resp := util.GetMethod(RaftMembersURL, bytes.NewBuffer([]byte{}))
	body, err := ioutil.ReadAll(resp.Body)

	var servers []string

	if err != nil {
		log.Printf("Error reading body: %v", err)
	} else {
		var raft Raft
		if err := json.Unmarshal(body, &raft); err != nil {
			panic(err)
		}

		for i := 0; i < len(raft.Servers); i++ {
			servers = append(servers, raft.Servers[i].Node)
		}
	}
	return servers
}

func registerService() {
	//TODO: Refactor of handlerRegister
}

func deregisterService() {
	//TODO: Refactor of handlerDeregister
}

func getNodeHealth(node string) bool {
	url := fmt.Sprintf(NodeHealthURL, node)
	resp := util.GetMethod(url, bytes.NewBuffer([]byte{}))
	body, err := ioutil.ReadAll(resp.Body)
	status := false

	if err != nil {
		log.Printf("Error reading body: %v", err)
	} else {
		var healths []HealthNode
		if err := json.Unmarshal(body, &healths); err != nil {
			panic(err)
		}

		for i := 0; i < len(healths); i++ {
			if healths[i].CheckID == "serfHealth" {
				status = healths[i].Status == "passing"
				i = len(healths)
			}
		}
	}

	return status
}

func getAgentMemberHealth(node string) bool {
	members := getAgentMembers()
	status := false

	for i := 0; i < len(members); i++ {
		if members[i].Name == node {
			status = members[i].Status == 1
			i = len(members)
		}
	}

	return status
}

func getAgentMembers() []AgentMember {
	resp := util.GetMethod(AgentMembersURL, bytes.NewBuffer([]byte{}))
	body, err := ioutil.ReadAll(resp.Body)
	var members []AgentMember

	if err != nil {
		log.Printf("Error reading body: %v", err)
	} else {
		if err := json.Unmarshal(body, &members); err != nil {
			panic(err)
		}
	}

	return members
}

func getCatalogNodeHealth(node string) bool {
	catalogNodes := getCatalogNodes(node)
	status := false

	for i := 0; i < len(catalogNodes); i++ {
		if catalogNodes[i].Node == node {
			status = catalogNodes[i].TaggedAddresses != (TaggedAddress{})
			i = len(catalogNodes)
		}
	}

	return status
}

func getCatalogNodes(orderedBy string) []CatalogNode {
	url := CatalogNodesURL
	if orderedBy != "" {
		url = fmt.Sprintf(CatalogNodesOrderedURL, orderedBy)
	}
	resp := util.GetMethod(url, bytes.NewBuffer([]byte{}))
	body, err := ioutil.ReadAll(resp.Body)
	var nodes []CatalogNode

	if err != nil {
		log.Printf("Error reading body: %v", err)
	} else {
		if err := json.Unmarshal(body, &nodes); err != nil {
			panic(err)
		}
	}

	return nodes
}

func getCompleteNodeHealth(node string) bool {
	status := getNodeHealth(node) &&
		getAgentMemberHealth(node) &&
		getCatalogNodeHealth(node)

	return status
}

///////////
// HANDLERS
///////////
func handlerServers(w http.ResponseWriter, r *http.Request) {
	servers := getServers()
	fmt.Fprintf(w, "%s\n", servers)
}

func handlerLeader(w http.ResponseWriter, r *http.Request) {
	leader := getLeader()
	fmt.Fprintf(w, "%s\n", leader)
}

func handlerRegister(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log.Printf("Error reading body: %v", err)
		http.Error(w, "can't read body", http.StatusBadRequest)
		return
	}
	responseMap := map[string]string{}
	for _, server := range getServers() {
		url := fmt.Sprintf(RegisterServiceURL, server)
		resp := util.PutMethod(url, bytes.NewBuffer(body))
		responseMap[server] = resp.Status
	}

	fmt.Fprintf(w, "Result: \n%s\n", responseMap)
}

func handlerDeregister(w http.ResponseWriter, r *http.Request) {
	responseMap := map[string]string{}
	service := strings.TrimPrefix(r.URL.Path, "/deregister/")
	for _, server := range getServers() {
		url := fmt.Sprintf(DeregisterServiceURL, server, service)
		resp := util.PutMethod(url, bytes.NewBuffer([]byte{}))
		responseMap[server] = resp.Status
	}

	fmt.Fprintf(w, "Result: \n%s\n", responseMap)
}

func handlerHealth(w http.ResponseWriter, r *http.Request) {
	node := strings.TrimPrefix(r.URL.Path, "/health/")
	status := StatusResponse{"Not OK"}
	if getCompleteNodeHealth(node) {
		status.Status = "OK"
	}
	output, _ := json.Marshal(status)
	fmt.Fprintf(w, "%s\n", output)
}

///////
// IMPLEMENTED FOR SERVICEDISCOVERY INTERFACE
///////
func (c Consul) RegisterEndpoints() {
	http.HandleFunc("/health/", handlerHealth)
	http.HandleFunc("/register", handlerRegister)
	http.HandleFunc("/deregister/", handlerDeregister)
	http.HandleFunc("/leader", handlerLeader)
	http.HandleFunc("/servers", handlerServers)
}

func (c Consul) LongPolling() {
	go polling()
}

func (c Consul) RunServer(port string) {
	log.Printf("Registrator listen on port %s ...\n", port)
	http.ListenAndServe(port, nil)
}
