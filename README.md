# gearSwap

  #auth
  # auth:
  #   Type: AWS::Serverless::Function
  #   Properties:
  #     CodeUri: auth/
  #     Handler: auth.lambda_handler
  #     Runtime: python3.12
  #     Policies:
  #       - AWSLambdaBasicExecutionRole

  # #login
  # loginFunc:
  #   Type: AWS::Serverless::Function
  #   Properties:
  #     Handler: login.lambda_handler
  #     Runtime: python3.12
  #     CodeUri: auth/
  #     Events:
  #       login:
  #         Type: Api
  #         Properties:
  #           Path: /login/{email}
  #           Method: post
  #     Layers:
  #       - !Ref PsycopgLayer