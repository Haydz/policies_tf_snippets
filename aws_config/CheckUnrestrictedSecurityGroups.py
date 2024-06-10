import json
import boto3

ec2 = boto3.client('ec2')
config = boto3.client('config')

def lambda_handler(event, context):
    print(json.dumps(event))
    
    try:
        # Extract necessary data from the event
        config_rule_name = event['configRuleName']
        account_id = event['accountId']
        configuration_item = json.loads(event['invokingEvent'])['configurationItem']
        security_group_id = configuration_item['configuration']['groupId'].strip()
        result_token = event.get('resultToken', 'No token provided')
        compliance_status = 'COMPLIANT'
        
        # Describe the security group to get its details
        response = ec2.describe_security_groups(GroupIds=[security_group_id])
        security_group = response['SecurityGroups'][0]

        # Check if any rules are allowing 0.0.0.0/0
        for permission in security_group['IpPermissions']:
            for ip_range in permission.get('IpRanges', []):
                if ip_range == '0.0.0.0/0' or ip_range.get('CidrIp') == '0.0.0.0/0':
                    compliance_status = 'NON_COMPLIANT'
                    break
        
        # Report compliance back to AWS Config
        config.put_evaluations(
            Evaluations=[
                {
                    'ComplianceResourceType': 'AWS::EC2::SecurityGroup',
                    'ComplianceResourceId': security_group_id,
                    'ComplianceType': compliance_status,
                    'Annotation': f'Security group is {compliance_status} for allowing 0.0.0.0/0.',
                    'OrderingTimestamp': configuration_item['configurationItemCaptureTime']
                },
            ],
            ResultToken=result_token
        )

        return {
            'statusCode': 200,
            'body': json.dumps(f'Security group {security_group_id} compliance status: {compliance_status}')
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
