import boto3
from botocore.exceptions import ClientError
import os
from enum import Enum
from typing import Dict, Optional

class EmailProvider(Enum):
    SES = "ses"

class EmailService:
    def __init__(self, provider: EmailProvider):
        self.provider = provider
        
        if provider == EmailProvider.SES:
            self.ses_client = boto3.client(
                'ses',
                region_name=os.environ.get('SES_REGION', 'us-east-2'),
            )
            # Verify SES configuration
            self._verify_ses_configuration()

    def _verify_ses_configuration(self):
        """Verify SES configuration and permissions"""
        try:
            # Test SES access by getting send quota
            self.ses_client.get_send_quota()
            print("SES configuration verified successfully")
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            print(f"SES configuration error: {error_code} - {error_message}")
            if error_code == 'InvalidClientTokenId':
                print("AWS credentials are invalid or not properly configured")
            elif error_code == 'AccessDenied':
                print("Lambda function lacks necessary SES permissions")
            raise

    def create_email_message(self, to_email: str, reset_token: str, userId: str) -> Dict:
        """Create the email message structure"""
        # reset_link = f"https://your-app-url/reset-password?token={reset_token}&userId={userId}"
        reset_link = f"https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/users/password-reset/verify?token={reset_token}&userId={userId}"
        
        return {
            'Source': os.environ['SES_SENDER_EMAIL'],
            'Destination': {
                'ToAddresses': [to_email]
            },
            'Message': {
                'Subject': {
                    'Data': 'Reset Your GearSwap Password',
                    'Charset': 'UTF-8'
                },
                'Body': {
                    'Html': {
                        'Data': f"""
                        <html>
                            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                                <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                                    <h2 style="color: #2c3e50;">Password Reset Request</h2>
                                    <p>Hello,</p>
                                    <p>We received a request to reset your password for your GearSwap account. 
                                       Click the button below to set a new password:</p>
                                    
                                    <div style="text-align: center; margin: 30px 0;">
                                        <a href="{reset_link}" 
                                           style="background-color: #3498db; 
                                                  color: white; 
                                                  padding: 12px 24px; 
                                                  text-decoration: none; 
                                                  border-radius: 4px; 
                                                  display: inline-block;">
                                            Reset Password
                                        </a>
                                    </div>
                                    
                                    <p>If you didn't request this password reset, please ignore this email 
                                       or contact support if you have concerns.</p>
                                    
                                    <p>This password reset link will expire in 24 hours.</p>
                                    
                                    <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee;">
                                        <p style="font-size: 12px; color: #666;">
                                            This is an automated message, please do not reply to this email.
                                        </p>
                                    </div>
                                </div>
                            </body>
                        </html>
                        """,
                        'Charset': 'UTF-8'
                    }
                }
            }
        }

    def send_reset_email(self, to_email: str, reset_token: str, userId: str) -> bool:
        """Send password reset email using configured provider"""
        try:
            if self.provider == EmailProvider.SES:
                message = self.create_email_message(to_email, reset_token, userId)
                
                try:
                    response = self.ses_client.send_email(**message)
                    print(f"Email sent successfully! Message ID: {response['MessageId']}")
                    return True
                except ClientError as e:
                    error_code = e.response['Error']['Code']
                    error_message = e.response['Error']['Message']
                    print(f"Failed to send email via {self.provider.value}: {error_code} - {error_message}")
                    raise
                    
        except Exception as e:
            print(f"Failed to send email via {self.provider.value}: {str(e)}")
            raise