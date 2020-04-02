#!/bin/bash

#create lambda function
REGION="eu-west-1"
NAME="serverless-controller-script"
APINAME="api-test"
LAMBDAARN=$(echo $(aws lambda create-function --function-name ${NAME} --zip-file fileb://lambda.py.zip --role serverless-controller-role --handler lambda.lambda_handler --runtime python3.7 --role arn:aws:iam::579355880153:role/service-role/serverless-controller-role) | jq -r '.FunctionArn')

#create api
APIID=$(echo $(aws apigateway create-rest-api --name "${APINAME}" --description "Api for ${NAME}" --region ${REGION})| jq -r '.id')
PARENTRESOURCEID=$(echo $(aws apigateway get-resources --rest-api-id ${APIID})| jq -r '.items[].id')
RESOURCEID=$(echo $(aws apigateway create-resource --rest-api-id ${APIID} --parent-id ${PARENTRESOURCEID} --path-part igor --region ${REGION})| jq -r '.id')

#Itegration
aws apigateway put-method --rest-api-id ${APIID} --resource-id ${RESOURCEID} --http-method POST --authorization-type NONE --region ${REGION}
aws apigateway put-integration --rest-api-id ${APIID} --resource-id ${RESOURCEID} --http-method POST --type AWS --integration-http-method POST --uri arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDAARN}/invocations --request-templates '{"application/x-www-form-urlencoded":"{\"body\": $input.json(\"$\")}"}' --region ${REGION}
aws apigateway put-method-response --rest-api-id ${APIID} --resource-id ${RESOURCEID} --http-method POST --status-code 200 --response-models "{}" --region ${REGION}
aws apigateway put-integration-response --rest-api-id ${APIID} --resource-id ${RESOURCEID} --http-method POST --status-code 200 --selection-pattern ".*" --region ${REGION}
aws apigateway create-deployment --rest-api-id ${APIID} --stage-name prod --region ${REGION}
APIARN=$(echo ${LAMBDAARN} | sed -e 's/lambda/execute-api/' -e "s/function:${NAME}/${APIID}/")
aws lambda add-permission --function-name ${NAME} --statement-id apigateway-igor-test-2 --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "${APIARN}/*/POST/igor" --region ${REGION}
aws lambda add-permission --function-name ${NAME} --statement-id apigateway-igor-prod-2 --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "${APIARN}/prod/POST/igor" --region ${REGION}

echo "The url is: https://${APIID}.execute-api.${REGION}.amazonaws.com/prod/igor"