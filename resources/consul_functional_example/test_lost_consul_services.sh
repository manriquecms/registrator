#####################
## REMOVE CONSUL CLUSTER
#####################
docker rm -f $(docker ps -qa)

#####################
## RUN CONSUL CLUSTER
## servers: consul1-3
## clients: consul4-6
#####################
docker run -d --name consul1 -v /home/cmanrique/cositas:/home/cmanrique/cositas -e CONSUL_LOCAL_CONFIG='{"enable_script_checks": true,"node_name":"consul1","datacenter":"eos","server":true,"enable_debug":true}' consul agent -server -bootstrap-expect=3
docker run -d --name consul2 -v /home/cmanrique/cositas:/home/cmanrique/cositas -e CONSUL_LOCAL_CONFIG='{"enable_script_checks": true,"node_name":"consul2","datacenter":"eos","server":true,"enable_debug":true, "retry_join":["172.28.16.1"]}' consul agent -server -bootstrap-expect=3
docker run -d --name consul3 -v /home/cmanrique/cositas:/home/cmanrique/cositas -e CONSUL_LOCAL_CONFIG='{"enable_script_checks": true,"node_name":"consul3","datacenter":"eos","server":true,"enable_debug":true, "retry_join":["172.28.16.1"]}' consul agent -server -bootstrap-expect=3
docker run -d --name consul4 -v /home/cmanrique/cositas:/home/cmanrique/cositas -e CONSUL_LOCAL_CONFIG='{"enable_script_checks": true,"node_name":"consul4","datacenter":"eos","server":false,"enable_debug":true, "retry_join":["172.28.16.1"]}' consul agent
docker run -d --name consul5 -v /home/cmanrique/cositas:/home/cmanrique/cositas -e CONSUL_LOCAL_CONFIG='{"enable_script_checks": true,"node_name":"consul5","datacenter":"eos","server":false,"enable_debug":true, "retry_join":["172.28.16.1"]}' consul agent
docker run -d --name consul6 -v /home/cmanrique/cositas:/home/cmanrique/cositas -e CONSUL_LOCAL_CONFIG='{"enable_script_checks": true,"node_name":"consul6","datacenter":"eos","server":false,"enable_debug":true, "retry_join":["172.28.16.1"]}' consul agent


docker run -d --name service1 testpython
docker run -d --name service2 testpython
docker run -d --name service3 testpython
docker run -d --name service4 testpython
docker run -d --name service5 testpython
docker run -d --name service6 testpython

docker inspect consul1 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect consul2 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect consul3 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect consul4 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect consul5 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect consul6 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect service1 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect service2 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect service3 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect service4 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect service5 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"
docker inspect service6 | jq '.[0].NetworkSettings.IPAddress' | tr -d \"

###################
## DESCRIBE CLUSTER
###################
docker exec -it consul1 consul members &
docker exec -it consul1 consul operator raft list-peers







###########################################
## REGISTER SERVICES TO 1 SERVER (NOT LEADER)
###########################################
docker exec -it consul1 curl --request PUT --data @/home/cmanrique/cositas/test1.json http://127.0.0.1:8500/v1/agent/service/register &
docker exec -it consul1 curl --request PUT --data @/home/cmanrique/cositas/test2.json http://127.0.0.1:8500/v1/agent/service/register &
docker exec -it consul1 curl --request PUT --data @/home/cmanrique/cositas/test3.json http://127.0.0.1:8500/v1/agent/service/register &
docker exec -it consul1 curl --request PUT --data @/home/cmanrique/cositas/test4.json http://127.0.0.1:8500/v1/agent/service/register &
docker exec -it consul1 curl --request PUT --data @/home/cmanrique/cositas/test5.json http://127.0.0.1:8500/v1/agent/service/register &
docker exec -it consul1 curl --request PUT --data @/home/cmanrique/cositas/test6.json http://127.0.0.1:8500/v1/agent/service/register

############################
## GET SERVICES IN ALL NODES
############################
docker exec -it consul1 consul watch -type=services &
docker exec -it consul2 consul watch -type=services &
docker exec -it consul3 consul watch -type=services &
docker exec -it consul4 consul watch -type=services &
docker exec -it consul5 consul watch -type=services &
docker exec -it consul6 consul watch -type=services

###########################################
## STOP SERVER THAT REGISTERED THE SERVICES
###########################################
docker stop consul2

###################################################
## GET SERVICES IN ALL NODES (EXCEPT consul2, down)
###################################################
docker exec -it consul1 consul watch -type=services &
docker exec -it consul3 consul watch -type=services &
docker exec -it consul4 consul watch -type=services &
docker exec -it consul5 consul watch -type=services &
docker exec -it consul6 consul watch -type=services

####################
## START SERVER DOWN
####################
docker start consul2

###########################################
## DEREGISTER SERVICES TO SERVER (NOT LEADER)
###########################################
docker exec -it consul1 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test1 &
docker exec -it consul1 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test2 &
docker exec -it consul1 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test3 &
docker exec -it consul1 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test4 &
docker exec -it consul1 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test5 &
docker exec -it consul1 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test6








##################################
## REGISTER SERVICES IN OWN AGENT
##################################
docker exec -it consul1 curl --request PUT --data @/home/cmanrique/cositas/test1.json http://127.0.0.1:8500/v1/agent/service/register &
docker exec -it consul2 curl --request PUT --data @/home/cmanrique/cositas/test2.json http://127.0.0.1:8500/v1/agent/service/register &
docker exec -it consul3 curl --request PUT --data @/home/cmanrique/cositas/test3.json http://127.0.0.1:8500/v1/agent/service/register &
docker exec -it consul4 curl --request PUT --data @/home/cmanrique/cositas/test4.json http://127.0.0.1:8500/v1/agent/service/register &
docker exec -it consul5 curl --request PUT --data @/home/cmanrique/cositas/test5.json http://127.0.0.1:8500/v1/agent/service/register &
docker exec -it consul6 curl --request PUT --data @/home/cmanrique/cositas/test6.json http://127.0.0.1:8500/v1/agent/service/register 

############################
## GET SERVICES IN ALL NODES
############################
docker exec -it consul1 consul watch -type=services &
docker exec -it consul2 consul watch -type=services &
docker exec -it consul3 consul watch -type=services &
docker exec -it consul4 consul watch -type=services &
docker exec -it consul5 consul watch -type=services &
docker exec -it consul6 consul watch -type=services

#############################
## STOP 1 SERVER AND 1 CLIENT
#############################
docker stop consul1 &
docker stop consul4

############################
## GET SERVICES IN ALL NODES
############################
docker exec -it consul2 consul watch -type=services &
docker exec -it consul3 consul watch -type=services &
docker exec -it consul5 consul watch -type=services &
docker exec -it consul6 consul watch -type=services

##############################
## START 1 SERVER AND 1 CLIENT
##############################
docker start consul1 &
docker start consul4

############################
## GET SERVICES IN ALL NODES
############################
docker exec -it consul1 consul watch -type=services &
docker exec -it consul2 consul watch -type=services &
docker exec -it consul3 consul watch -type=services &
docker exec -it consul4 consul watch -type=services &
docker exec -it consul5 consul watch -type=services &
docker exec -it consul6 consul watch -type=services

###########################################
## DEREGISTER SERVICES TO SERVER (NOT LEADER)
###########################################
docker exec -it consul1 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test1 &
docker exec -it consul2 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test2 &
docker exec -it consul3 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test3 &
docker exec -it consul4 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test4 &
docker exec -it consul5 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test5 &
docker exec -it consul6 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test6

#############
## TESTING KV
############# &
docker exec -it consul1 consul kv put examples/example1 val1 &
docker exec -it consul1 consul kv put example_det1 val_det1 &
docker exec -it consul2 consul kv put examples/example2 val2 &
docker exec -it consul2 consul kv put example_det2 val_det2 &
docker exec -it consul3 consul kv put examples/example3 val3 &
docker exec -it consul3 consul kv put example_det3 val_det3 &
docker exec -it consul4 consul kv put examples/example4 val4 &
docker exec -it consul4 consul kv put example_det4 val_det4 &
docker exec -it consul5 consul kv put examples/example5 val5 &
docker exec -it consul5 consul kv put example_det5 val_det5 &
docker exec -it consul6 consul kv put examples/example6 val6 &
docker exec -it consul6 consul kv put example_det6 val_det6

#docker exec -it consul2 curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/test1