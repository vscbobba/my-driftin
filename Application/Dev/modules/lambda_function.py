import boto3
import json

def lambda_handler(event, context):
    ec2_client = boto3.client('ec2')
    sns_client = boto3.client('sns')
    sns_topic_arn = 'arn:aws:sns:ap-south-1:631231558475:workspace-start-stop'  # Replace with your SNS topic ARN
    
    # Check if the event is an object deletion
    for record in event['Records']:
        if record['eventName'].startswith('ObjectRemoved:'):
            # Find the instance with the specific tag
            instances = ec2_client.describe_instances(
                Filters=[
                    {
                        'Name': 'tag:Name',
                        'Values': ['workspace']
                    }
                ]
            )
            instance_ids = [instance['InstanceId'] for reservation in instances['Reservations'] for instance in reservation['Instances']]
            
            if instance_ids:
                # Terminate the EC2 instance
                response = ec2_client.terminate_instances(
                    InstanceIds=instance_ids
                )
                print("EC2 Instance Terminated: ", response)
                
                # Publish SNS notification
                sns_response = sns_client.publish(
                    TopicArn=sns_topic_arn,
                    Message=f"EC2 instance(s) {instance_ids} terminated successfully.",
                    Subject="EC2 Instance Termination"
                )
                print("SNS Notification Sent: ", sns_response)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps('EC2 instance terminated successfully!')
                }
    
    # If the event is not an object deletion, create an EC2 instance
    response = ec2_client.run_instances(
        LaunchTemplate={
            'LaunchTemplateName': 'WORKSPACE',  # Replace with your launch template name
            'Version': '$Latest'
        },
        MinCount=1,
        MaxCount=1,
        TagSpecifications=[
            {
                'ResourceType': 'instance',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': 'workspace'
                    }
                ]
            }
        ]
    )
    
    instance_id = response['Instances'][0]['InstanceId']
    print("EC2 Instance Created: ", response)
    
    # Publish SNS notification
    sns_response = sns_client.publish(
        TopicArn=sns_topic_arn,
        Message=f"EC2 instance {instance_id} created successfully.",
        Subject="EC2 Instance Creation"
    )
    print("SNS Notification Sent: ", sns_response)
    
    return {
        'statusCode': 200,
        'body': json.dumps('EC2 instance created successfully!')
    }