import json
import boto3

ec2 = boto3.client('ec2')
config = boto3.client('config')

def lambda_handler(event, context):
    print("Received event: ", json.dumps(event, indent=2))
    
    try:
        security_group_id = event.get('SecurityGroupId', '').strip()
        
        if not security_group_id:
            raise ValueError("SecurityGroupId is missing from the event")

        # Describe the security group to get its details
        response = ec2.describe_security_groups(GroupIds=[security_group_id])
        security_group = response['SecurityGroups'][0]

        # Remove rules that allow 0.0.0.0/0
        for permission in security_group['IpPermissions']:
            for ip_range in permission.get('IpRanges', []):
                if ip_range == '0.0.0.0/0' or ip_range.get('CidrIp') == '0.0.0.0/0':
                    protocol = permission.get('IpProtocol', '')
                    from_port = permission.get('FromPort')
                    to_port = permission.get('ToPort')

                    ec2.revoke_security_group_ingress(
                        GroupId=security_group_id,
                        IpProtocol=protocol,
                        FromPort=from_port,
                        ToPort=to_port,
                        CidrIp='0.0.0.0/0'
                    )
                    print(f"Revoked rule allowing 0.0.0.0/0 for {protocol} from {from_port} to {to_port}")
        
        print(f"Security group {security_group_id} has been remediated")
        return {
            'statusCode': 200,
            'body': json.dumps('Security group rules remediated successfully!')
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
