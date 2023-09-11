#!/bin/bash
export TEST=1234
#sed -i s/\$image/$(echo -n $TEST)/g customer-deployment.yaml
sed -i '' -e s/\$image/$(echo -n $TEST)/ ./customer-deployment.yaml
#sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo