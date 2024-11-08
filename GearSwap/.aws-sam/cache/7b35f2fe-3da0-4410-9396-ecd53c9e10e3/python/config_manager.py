import boto3
from botocore.exceptions import ClientError
import os

class ConfigManager:
    def __init__(self):
        self.secrets = boto3.client('secretsmanager')
        self.ssm = boto3.client('ssm')
        self.env = os.getenv('ENV', 'dev')
        
    def get_secret(self, secret_name: str) -> str:
        """Get a secret from AWS Secrets Manager"""
        try:
            full_path = f"/gearswap/{self.env}/{secret_name}"
            response = self.secrets.get_secret_value(
                SecretId=full_path
            )
            return response['SecretString']
        except ClientError as e:
            print(f"Error getting secret {secret_name} at path {full_path}: {str(e)}")
            raise

    def get_parameter(self, param_name: str) -> str:
        """Get a parameter from AWS SSM Parameter Store"""
        try:
            full_path = f"/gearswap/{self.env}/{param_name}"
            response = self.ssm.get_parameter(
                Name=full_path,
                WithDecryption=True
            )
            return response['Parameter']['Value']
        except ClientError as e:
            print(f"Error getting parameter {param_name} at path {full_path}: {str(e)}")
            raise

config_manager = ConfigManager()