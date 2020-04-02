#!/bin/bash

a=$(aws elbv2 create-load-balancer --name autoloadbalancer --type network --subnets subnet-b2380dfa)

lb_arn=$(echo "$a"| jq -r '.LoadBalancers[].LoadBalancerArn')
echo ${lb_arn}

b=$(aws elbv2 create-target-group --name my-targets --protocol TCP --port 80 --vpc-id vpc-3d55bc44)

tg_arn=$(echo "$b"| jq -r '.TargetGroups[].TargetGroupArn')
echo ${tg_arn}

aws elbv2 register-targets --target-group-arn ${tg_arn} --targets Id=i-0f67783318e3027b8 Id=i-0f7f7e30891485742\

aws elbv2 create-listener --load-balancer-arn ${lb_arn} --protocol TCP --port 80 --default-actions Type=forward,TargetGroupArn=${tg_arn}
