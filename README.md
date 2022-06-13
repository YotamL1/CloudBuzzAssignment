##Assigmnemt for CloudBuzz By Yotam Levy


#####To test this application you can either use:
>Curl
>>CURL -G -d Key1=number -d Key2=number https://1ivg3mp334.execute-api.us-east-1.amazonaws.com/Test/calc>

>Or use the following URL:
>>https://1ivg3mp334.execute-api.us-east-1.amazonaws.com/Test/calc/?Key1=number&Key2=number

After learning Terraform I was able to add the first stage via terraform, you can check it out with the following commands:
>AWS CLI to invoke the function
>> aws lambda invoke --region=us-east-1 --function-name="lambda_handler" --cli-binary-format raw-in-base64-out --payload '{\"Key1\":1,\"Key2\":3}' response.json

>AWS CLI to subscribe to the sns
>>aws sns subscribe --topic-arn=arn:aws:sns:us-east-1:582091735727:test_terraform --protocol email --notification-endpoint your-email
