#!/bin/bash
#in agent-1
docker build --tag testpython .
docker run -d --net=host --name service1 testpython

