import boto3
import os
from botocore.exceptions import ClientError

class ConfigManager:
    def __init__(self):
        self.ssm = boto3.client('ssm')
        self.env = os.getenv('ENV', 'dev')
        
    def get_parameter(self, param_name: str, decrypt: bool = True) -> str:
        """
        Get a parameter from SSM Parameter Store
        """
        try:
            parameter = self.ssm.get_parameter(
                Name=f'/gearswap/{self.env}/{param_name}',
                WithDecryption=decrypt
            )
            return parameter['Parameter']['Value']
        except ClientError as e:
            print(f"Error getting parameter {param_name}: {str(e)}")
            raise

    def get_all_parameters(self) -> dict:
        """
        Get all parameters for the current environment
        """
        params = {}
        try:
            paginator = self.ssm.get_paginator('get_parameters_by_path')
            for page in paginator.paginate(
                Path=f'/gearswap/{self.env}/',
                Recursive=True,
                WithDecryption=True
            ):
                for param in page['Parameters']:
                    # Extract the parameter name without the path prefix
                    name = param['Name'].split('/')[-1]
                    params[name] = param['Value']
            return params
        except ClientError as e:
            print(f"Error getting parameters: {str(e)}")
            raise

config_manager = ConfigManager()