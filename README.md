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

  # #posts
  # posts:
  #   Type: AWS::Serverless::Function
  #   Properties:
  #     Handler: posts.lambda_handler
  #     Runtime: python3.12
  #     CodeUri: posts/
  #     Events:
  #       getPost:
  #         Type: Api
  #         Properties:
  #           Path: /posts/{id}
  #           Method: get
  #       createPost:
  #         Type: Api
  #         Properties:
  #           Path: /posts
  #           Method: post
  #       updateUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: put
  #       deleteUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: delete
  #       getUserFollowers:
  #         Type: Api
  #         Properties:
  #           Path: /users/followers/{userId}
  #           Method: get
  #       getUserFollowing:
  #         Type: Api
  #         Properties:
  #           Path: /users/following/{userId}
  #           Method: get
  #     Layers:
  #       - !Ref PsycopgLayer

  # #profile
  # users:
  #   Type: AWS::Serverless::Function
  #   Properties:
  #     Handler: users.lambda_handler
  #     Runtime: python3.12
  #     CodeUri: users/
  #     Events:
  #       getUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: get
  #       createUser:
  #         Type: Api
  #         Properties:
  #           Path: /users
  #           Method: post
  #       updateUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: put
  #       deleteUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: delete
  #       getUserFollowers:
  #         Type: Api
  #         Properties:
  #           Path: /users/followers/{userId}
  #           Method: get
  #       getUserFollowing:
  #         Type: Api
  #         Properties:
  #           Path: /users/following/{userId}
  #           Method: get
  #     Layers:
  #       - !Ref PsycopgLayer

  # #cart
  # users:
  #   Type: AWS::Serverless::Function
  #   Properties:
  #     Handler: users.lambda_handler
  #     Runtime: python3.12
  #     CodeUri: users/
  #     Events:
  #       getUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: get
  #       createUser:
  #         Type: Api
  #         Properties:
  #           Path: /users
  #           Method: post
  #       updateUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: put
  #       deleteUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: delete
  #       getUserFollowers:
  #         Type: Api
  #         Properties:
  #           Path: /users/followers/{userId}
  #           Method: get
  #       getUserFollowing:
  #         Type: Api
  #         Properties:
  #           Path: /users/following/{userId}
  #           Method: get
  #     Layers:
  #       - !Ref PsycopgLayer

  # #outfit
  # users:
  #   Type: AWS::Serverless::Function
  #   Properties:
  #     Handler: users.lambda_handler
  #     Runtime: python3.12
  #     CodeUri: users/
  #     Events:
  #       getUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: get
  #       createUser:
  #         Type: Api
  #         Properties:
  #           Path: /users
  #           Method: post
  #       updateUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: put
  #       deleteUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: delete
  #       getUserFollowers:
  #         Type: Api
  #         Properties:
  #           Path: /users/followers/{userId}
  #           Method: get
  #       getUserFollowing:
  #         Type: Api
  #         Properties:
  #           Path: /users/following/{userId}
  #           Method: get
  #     Layers:
  #       - !Ref PsycopgLayer

  # #search
  # users:
  #   Type: AWS::Serverless::Function
  #   Properties:
  #     Handler: users.lambda_handler
  #     Runtime: python3.12
  #     CodeUri: users/
  #     Events:
  #       getUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: get
  #       createUser:
  #         Type: Api
  #         Properties:
  #           Path: /users
  #           Method: post
  #       updateUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: put
  #       deleteUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: delete
  #       getUserFollowers:
  #         Type: Api
  #         Properties:
  #           Path: /users/followers/{userId}
  #           Method: get
  #       getUserFollowing:
  #         Type: Api
  #         Properties:
  #           Path: /users/following/{userId}
  #           Method: get
  #     Layers:
  #       - !Ref PsycopgLayer

  # #styler
  # users:
  #   Type: AWS::Serverless::Function
  #   Properties:
  #     Handler: users.lambda_handler
  #     Runtime: python3.12
  #     CodeUri: users/
  #     Events:
  #       getUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: get
  #       createUser:
  #         Type: Api
  #         Properties:
  #           Path: /users
  #           Method: post
  #       updateUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: put
  #       deleteUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: delete
  #       getUserFollowers:
  #         Type: Api
  #         Properties:
  #           Path: /users/followers/{userId}
  #           Method: get
  #       getUserFollowing:
  #         Type: Api
  #         Properties:
  #           Path: /users/following/{userId}
  #           Method: get
  #     Layers:
  #       - !Ref PsycopgLayer

  # #interests
  # users:
  #   Type: AWS::Serverless::Function
  #   Properties:
  #     Handler: users.lambda_handler
  #     Runtime: python3.12
  #     CodeUri: users/
  #     Events:
  #       getUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: get
  #       createUser:
  #         Type: Api
  #         Properties:
  #           Path: /users
  #           Method: post
  #       updateUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: put
  #       deleteUser:
  #         Type: Api
  #         Properties:
  #           Path: /users/{id}
  #           Method: delete
  #       getUserFollowers:
  #         Type: Api
  #         Properties:
  #           Path: /users/followers/{userId}
  #           Method: get
  #       getUserFollowing:
  #         Type: Api
  #         Properties:
  #           Path: /users/following/{userId}
  #           Method: get
  #     Layers:
  #       - !Ref PsycopgLayer

Outputs:
  # ServerlessRestApi is an implicit API created out of Events key under Serverless::Function
  # Find out more about other implicit resources you can reference within SAM
  # https://github.com/awslabs/serverless-application-model/blob/master/docs/internals/generated_resources.rst#api