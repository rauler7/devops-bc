#!/bin/bash
LB_IP=$$(kubectl get svc/foo-service -n microservice -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
for i in {1..5}; do
  echo "Request $i:"
  curl "${LB_IP}:5678"
  echo -e "\\n"
  sleep 1
done
