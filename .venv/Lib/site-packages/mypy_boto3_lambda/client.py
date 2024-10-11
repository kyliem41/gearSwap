"""
Type annotations for lambda service client.

[Open documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/)

Usage::

    ```python
    from boto3.session import Session
    from mypy_boto3_lambda.client import LambdaClient

    session = Session()
    client: LambdaClient = session.client("lambda")
    ```
"""

import sys
from typing import Any, Dict, Mapping, Type, overload

from botocore.client import BaseClient, ClientMeta

from .paginator import (
    ListAliasesPaginator,
    ListCodeSigningConfigsPaginator,
    ListEventSourceMappingsPaginator,
    ListFunctionEventInvokeConfigsPaginator,
    ListFunctionsByCodeSigningConfigPaginator,
    ListFunctionsPaginator,
    ListFunctionUrlConfigsPaginator,
    ListLayersPaginator,
    ListLayerVersionsPaginator,
    ListProvisionedConcurrencyConfigsPaginator,
    ListVersionsByFunctionPaginator,
)
from .type_defs import (
    AddLayerVersionPermissionRequestRequestTypeDef,
    AddLayerVersionPermissionResponseTypeDef,
    AddPermissionRequestRequestTypeDef,
    AddPermissionResponseTypeDef,
    AliasConfigurationResponseTypeDef,
    ConcurrencyResponseTypeDef,
    CreateAliasRequestRequestTypeDef,
    CreateCodeSigningConfigRequestRequestTypeDef,
    CreateCodeSigningConfigResponseTypeDef,
    CreateEventSourceMappingRequestRequestTypeDef,
    CreateFunctionRequestRequestTypeDef,
    CreateFunctionUrlConfigRequestRequestTypeDef,
    CreateFunctionUrlConfigResponseTypeDef,
    DeleteAliasRequestRequestTypeDef,
    DeleteCodeSigningConfigRequestRequestTypeDef,
    DeleteEventSourceMappingRequestRequestTypeDef,
    DeleteFunctionCodeSigningConfigRequestRequestTypeDef,
    DeleteFunctionConcurrencyRequestRequestTypeDef,
    DeleteFunctionEventInvokeConfigRequestRequestTypeDef,
    DeleteFunctionRequestRequestTypeDef,
    DeleteFunctionUrlConfigRequestRequestTypeDef,
    DeleteLayerVersionRequestRequestTypeDef,
    DeleteProvisionedConcurrencyConfigRequestRequestTypeDef,
    EmptyResponseMetadataTypeDef,
    EventSourceMappingConfigurationResponseTypeDef,
    FunctionConfigurationResponseTypeDef,
    FunctionEventInvokeConfigResponseTypeDef,
    GetAccountSettingsResponseTypeDef,
    GetAliasRequestRequestTypeDef,
    GetCodeSigningConfigRequestRequestTypeDef,
    GetCodeSigningConfigResponseTypeDef,
    GetEventSourceMappingRequestRequestTypeDef,
    GetFunctionCodeSigningConfigRequestRequestTypeDef,
    GetFunctionCodeSigningConfigResponseTypeDef,
    GetFunctionConcurrencyRequestRequestTypeDef,
    GetFunctionConcurrencyResponseTypeDef,
    GetFunctionConfigurationRequestRequestTypeDef,
    GetFunctionEventInvokeConfigRequestRequestTypeDef,
    GetFunctionRecursionConfigRequestRequestTypeDef,
    GetFunctionRecursionConfigResponseTypeDef,
    GetFunctionRequestRequestTypeDef,
    GetFunctionResponseTypeDef,
    GetFunctionUrlConfigRequestRequestTypeDef,
    GetFunctionUrlConfigResponseTypeDef,
    GetLayerVersionByArnRequestRequestTypeDef,
    GetLayerVersionPolicyRequestRequestTypeDef,
    GetLayerVersionPolicyResponseTypeDef,
    GetLayerVersionRequestRequestTypeDef,
    GetLayerVersionResponseTypeDef,
    GetPolicyRequestRequestTypeDef,
    GetPolicyResponseTypeDef,
    GetProvisionedConcurrencyConfigRequestRequestTypeDef,
    GetProvisionedConcurrencyConfigResponseTypeDef,
    GetRuntimeManagementConfigRequestRequestTypeDef,
    GetRuntimeManagementConfigResponseTypeDef,
    InvocationRequestRequestTypeDef,
    InvocationResponseTypeDef,
    InvokeAsyncRequestRequestTypeDef,
    InvokeAsyncResponseTypeDef,
    InvokeWithResponseStreamRequestRequestTypeDef,
    InvokeWithResponseStreamResponseTypeDef,
    ListAliasesRequestRequestTypeDef,
    ListAliasesResponseTypeDef,
    ListCodeSigningConfigsRequestRequestTypeDef,
    ListCodeSigningConfigsResponseTypeDef,
    ListEventSourceMappingsRequestRequestTypeDef,
    ListEventSourceMappingsResponseTypeDef,
    ListFunctionEventInvokeConfigsRequestRequestTypeDef,
    ListFunctionEventInvokeConfigsResponseTypeDef,
    ListFunctionsByCodeSigningConfigRequestRequestTypeDef,
    ListFunctionsByCodeSigningConfigResponseTypeDef,
    ListFunctionsRequestRequestTypeDef,
    ListFunctionsResponseTypeDef,
    ListFunctionUrlConfigsRequestRequestTypeDef,
    ListFunctionUrlConfigsResponseTypeDef,
    ListLayersRequestRequestTypeDef,
    ListLayersResponseTypeDef,
    ListLayerVersionsRequestRequestTypeDef,
    ListLayerVersionsResponseTypeDef,
    ListProvisionedConcurrencyConfigsRequestRequestTypeDef,
    ListProvisionedConcurrencyConfigsResponseTypeDef,
    ListTagsRequestRequestTypeDef,
    ListTagsResponseTypeDef,
    ListVersionsByFunctionRequestRequestTypeDef,
    ListVersionsByFunctionResponseTypeDef,
    PublishLayerVersionRequestRequestTypeDef,
    PublishLayerVersionResponseTypeDef,
    PublishVersionRequestRequestTypeDef,
    PutFunctionCodeSigningConfigRequestRequestTypeDef,
    PutFunctionCodeSigningConfigResponseTypeDef,
    PutFunctionConcurrencyRequestRequestTypeDef,
    PutFunctionEventInvokeConfigRequestRequestTypeDef,
    PutFunctionRecursionConfigRequestRequestTypeDef,
    PutFunctionRecursionConfigResponseTypeDef,
    PutProvisionedConcurrencyConfigRequestRequestTypeDef,
    PutProvisionedConcurrencyConfigResponseTypeDef,
    PutRuntimeManagementConfigRequestRequestTypeDef,
    PutRuntimeManagementConfigResponseTypeDef,
    RemoveLayerVersionPermissionRequestRequestTypeDef,
    RemovePermissionRequestRequestTypeDef,
    TagResourceRequestRequestTypeDef,
    UntagResourceRequestRequestTypeDef,
    UpdateAliasRequestRequestTypeDef,
    UpdateCodeSigningConfigRequestRequestTypeDef,
    UpdateCodeSigningConfigResponseTypeDef,
    UpdateEventSourceMappingRequestRequestTypeDef,
    UpdateFunctionCodeRequestRequestTypeDef,
    UpdateFunctionConfigurationRequestRequestTypeDef,
    UpdateFunctionEventInvokeConfigRequestRequestTypeDef,
    UpdateFunctionUrlConfigRequestRequestTypeDef,
    UpdateFunctionUrlConfigResponseTypeDef,
)
from .waiter import (
    FunctionActiveV2Waiter,
    FunctionActiveWaiter,
    FunctionExistsWaiter,
    FunctionUpdatedV2Waiter,
    FunctionUpdatedWaiter,
    PublishedVersionActiveWaiter,
)

if sys.version_info >= (3, 12):
    from typing import Literal, Unpack
else:
    from typing_extensions import Literal, Unpack


__all__ = ("LambdaClient",)


class BotocoreClientError(Exception):
    MSG_TEMPLATE: str

    def __init__(self, error_response: Mapping[str, Any], operation_name: str) -> None:
        self.response: Dict[str, Any]
        self.operation_name: str


class Exceptions:
    ClientError: Type[BotocoreClientError]
    CodeSigningConfigNotFoundException: Type[BotocoreClientError]
    CodeStorageExceededException: Type[BotocoreClientError]
    CodeVerificationFailedException: Type[BotocoreClientError]
    EC2AccessDeniedException: Type[BotocoreClientError]
    EC2ThrottledException: Type[BotocoreClientError]
    EC2UnexpectedException: Type[BotocoreClientError]
    EFSIOException: Type[BotocoreClientError]
    EFSMountConnectivityException: Type[BotocoreClientError]
    EFSMountFailureException: Type[BotocoreClientError]
    EFSMountTimeoutException: Type[BotocoreClientError]
    ENILimitReachedException: Type[BotocoreClientError]
    InvalidCodeSignatureException: Type[BotocoreClientError]
    InvalidParameterValueException: Type[BotocoreClientError]
    InvalidRequestContentException: Type[BotocoreClientError]
    InvalidRuntimeException: Type[BotocoreClientError]
    InvalidSecurityGroupIDException: Type[BotocoreClientError]
    InvalidSubnetIDException: Type[BotocoreClientError]
    InvalidZipFileException: Type[BotocoreClientError]
    KMSAccessDeniedException: Type[BotocoreClientError]
    KMSDisabledException: Type[BotocoreClientError]
    KMSInvalidStateException: Type[BotocoreClientError]
    KMSNotFoundException: Type[BotocoreClientError]
    PolicyLengthExceededException: Type[BotocoreClientError]
    PreconditionFailedException: Type[BotocoreClientError]
    ProvisionedConcurrencyConfigNotFoundException: Type[BotocoreClientError]
    RecursiveInvocationException: Type[BotocoreClientError]
    RequestTooLargeException: Type[BotocoreClientError]
    ResourceConflictException: Type[BotocoreClientError]
    ResourceInUseException: Type[BotocoreClientError]
    ResourceNotFoundException: Type[BotocoreClientError]
    ResourceNotReadyException: Type[BotocoreClientError]
    ServiceException: Type[BotocoreClientError]
    SnapStartException: Type[BotocoreClientError]
    SnapStartNotReadyException: Type[BotocoreClientError]
    SnapStartTimeoutException: Type[BotocoreClientError]
    SubnetIPAddressLimitReachedException: Type[BotocoreClientError]
    TooManyRequestsException: Type[BotocoreClientError]
    UnsupportedMediaTypeException: Type[BotocoreClientError]


class LambdaClient(BaseClient):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/)
    """

    meta: ClientMeta

    @property
    def exceptions(self) -> Exceptions:
        """
        LambdaClient exceptions.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.exceptions)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#exceptions)
        """

    def add_layer_version_permission(
        self, **kwargs: Unpack[AddLayerVersionPermissionRequestRequestTypeDef]
    ) -> AddLayerVersionPermissionResponseTypeDef:
        """
        Adds permissions to the resource-based policy of a version of an [Lambda
        layer](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.add_layer_version_permission)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#add_layer_version_permission)
        """

    def add_permission(
        self, **kwargs: Unpack[AddPermissionRequestRequestTypeDef]
    ) -> AddPermissionResponseTypeDef:
        """
        Grants a
        [principal](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#Principal_specifying)
        permission to use a
        function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.add_permission)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#add_permission)
        """

    def can_paginate(self, operation_name: str) -> bool:
        """
        Check if an operation can be paginated.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.can_paginate)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#can_paginate)
        """

    def close(self) -> None:
        """
        Closes underlying endpoint connections.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.close)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#close)
        """

    def create_alias(
        self, **kwargs: Unpack[CreateAliasRequestRequestTypeDef]
    ) -> AliasConfigurationResponseTypeDef:
        """
        Creates an
        [alias](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html)
        for a Lambda function
        version.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.create_alias)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#create_alias)
        """

    def create_code_signing_config(
        self, **kwargs: Unpack[CreateCodeSigningConfigRequestRequestTypeDef]
    ) -> CreateCodeSigningConfigResponseTypeDef:
        """
        Creates a code signing configuration.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.create_code_signing_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#create_code_signing_config)
        """

    def create_event_source_mapping(
        self, **kwargs: Unpack[CreateEventSourceMappingRequestRequestTypeDef]
    ) -> EventSourceMappingConfigurationResponseTypeDef:
        """
        Creates a mapping between an event source and an Lambda function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.create_event_source_mapping)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#create_event_source_mapping)
        """

    def create_function(
        self, **kwargs: Unpack[CreateFunctionRequestRequestTypeDef]
    ) -> FunctionConfigurationResponseTypeDef:
        """
        Creates a Lambda function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.create_function)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#create_function)
        """

    def create_function_url_config(
        self, **kwargs: Unpack[CreateFunctionUrlConfigRequestRequestTypeDef]
    ) -> CreateFunctionUrlConfigResponseTypeDef:
        """
        Creates a Lambda function URL with the specified configuration parameters.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.create_function_url_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#create_function_url_config)
        """

    def delete_alias(
        self, **kwargs: Unpack[DeleteAliasRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Deletes a Lambda function
        [alias](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.delete_alias)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#delete_alias)
        """

    def delete_code_signing_config(
        self, **kwargs: Unpack[DeleteCodeSigningConfigRequestRequestTypeDef]
    ) -> Dict[str, Any]:
        """
        Deletes the code signing configuration.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.delete_code_signing_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#delete_code_signing_config)
        """

    def delete_event_source_mapping(
        self, **kwargs: Unpack[DeleteEventSourceMappingRequestRequestTypeDef]
    ) -> EventSourceMappingConfigurationResponseTypeDef:
        """
        Deletes an [event source
        mapping](https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.delete_event_source_mapping)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#delete_event_source_mapping)
        """

    def delete_function(
        self, **kwargs: Unpack[DeleteFunctionRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Deletes a Lambda function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.delete_function)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#delete_function)
        """

    def delete_function_code_signing_config(
        self, **kwargs: Unpack[DeleteFunctionCodeSigningConfigRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Removes the code signing configuration from the function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.delete_function_code_signing_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#delete_function_code_signing_config)
        """

    def delete_function_concurrency(
        self, **kwargs: Unpack[DeleteFunctionConcurrencyRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Removes a concurrent execution limit from a function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.delete_function_concurrency)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#delete_function_concurrency)
        """

    def delete_function_event_invoke_config(
        self, **kwargs: Unpack[DeleteFunctionEventInvokeConfigRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Deletes the configuration for asynchronous invocation for a function, version,
        or
        alias.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.delete_function_event_invoke_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#delete_function_event_invoke_config)
        """

    def delete_function_url_config(
        self, **kwargs: Unpack[DeleteFunctionUrlConfigRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Deletes a Lambda function URL.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.delete_function_url_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#delete_function_url_config)
        """

    def delete_layer_version(
        self, **kwargs: Unpack[DeleteLayerVersionRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Deletes a version of an [Lambda
        layer](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.delete_layer_version)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#delete_layer_version)
        """

    def delete_provisioned_concurrency_config(
        self, **kwargs: Unpack[DeleteProvisionedConcurrencyConfigRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Deletes the provisioned concurrency configuration for a function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.delete_provisioned_concurrency_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#delete_provisioned_concurrency_config)
        """

    def generate_presigned_url(
        self,
        ClientMethod: str,
        Params: Mapping[str, Any] = ...,
        ExpiresIn: int = 3600,
        HttpMethod: str = ...,
    ) -> str:
        """
        Generate a presigned url given a client, its method, and arguments.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.generate_presigned_url)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#generate_presigned_url)
        """

    def get_account_settings(self) -> GetAccountSettingsResponseTypeDef:
        """
        Retrieves details about your account's
        [limits](https://docs.aws.amazon.com/lambda/latest/dg/limits.html) and usage in
        an Amazon Web Services
        Region.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_account_settings)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_account_settings)
        """

    def get_alias(
        self, **kwargs: Unpack[GetAliasRequestRequestTypeDef]
    ) -> AliasConfigurationResponseTypeDef:
        """
        Returns details about a Lambda function
        [alias](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_alias)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_alias)
        """

    def get_code_signing_config(
        self, **kwargs: Unpack[GetCodeSigningConfigRequestRequestTypeDef]
    ) -> GetCodeSigningConfigResponseTypeDef:
        """
        Returns information about the specified code signing configuration.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_code_signing_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_code_signing_config)
        """

    def get_event_source_mapping(
        self, **kwargs: Unpack[GetEventSourceMappingRequestRequestTypeDef]
    ) -> EventSourceMappingConfigurationResponseTypeDef:
        """
        Returns details about an event source mapping.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_event_source_mapping)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_event_source_mapping)
        """

    def get_function(
        self, **kwargs: Unpack[GetFunctionRequestRequestTypeDef]
    ) -> GetFunctionResponseTypeDef:
        """
        Returns information about the function or function version, with a link to
        download the deployment package that's valid for 10
        minutes.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_function)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_function)
        """

    def get_function_code_signing_config(
        self, **kwargs: Unpack[GetFunctionCodeSigningConfigRequestRequestTypeDef]
    ) -> GetFunctionCodeSigningConfigResponseTypeDef:
        """
        Returns the code signing configuration for the specified function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_function_code_signing_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_function_code_signing_config)
        """

    def get_function_concurrency(
        self, **kwargs: Unpack[GetFunctionConcurrencyRequestRequestTypeDef]
    ) -> GetFunctionConcurrencyResponseTypeDef:
        """
        Returns details about the reserved concurrency configuration for a function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_function_concurrency)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_function_concurrency)
        """

    def get_function_configuration(
        self, **kwargs: Unpack[GetFunctionConfigurationRequestRequestTypeDef]
    ) -> FunctionConfigurationResponseTypeDef:
        """
        Returns the version-specific settings of a Lambda function or version.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_function_configuration)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_function_configuration)
        """

    def get_function_event_invoke_config(
        self, **kwargs: Unpack[GetFunctionEventInvokeConfigRequestRequestTypeDef]
    ) -> FunctionEventInvokeConfigResponseTypeDef:
        """
        Retrieves the configuration for asynchronous invocation for a function,
        version, or
        alias.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_function_event_invoke_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_function_event_invoke_config)
        """

    def get_function_recursion_config(
        self, **kwargs: Unpack[GetFunctionRecursionConfigRequestRequestTypeDef]
    ) -> GetFunctionRecursionConfigResponseTypeDef:
        """
        Returns your function's [recursive loop
        detection](https://docs.aws.amazon.com/lambda/latest/dg/invocation-recursion.html)
        configuration.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_function_recursion_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_function_recursion_config)
        """

    def get_function_url_config(
        self, **kwargs: Unpack[GetFunctionUrlConfigRequestRequestTypeDef]
    ) -> GetFunctionUrlConfigResponseTypeDef:
        """
        Returns details about a Lambda function URL.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_function_url_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_function_url_config)
        """

    def get_layer_version(
        self, **kwargs: Unpack[GetLayerVersionRequestRequestTypeDef]
    ) -> GetLayerVersionResponseTypeDef:
        """
        Returns information about a version of an [Lambda
        layer](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html),
        with a link to download the layer archive that's valid for 10
        minutes.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_layer_version)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_layer_version)
        """

    def get_layer_version_by_arn(
        self, **kwargs: Unpack[GetLayerVersionByArnRequestRequestTypeDef]
    ) -> GetLayerVersionResponseTypeDef:
        """
        Returns information about a version of an [Lambda
        layer](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html),
        with a link to download the layer archive that's valid for 10
        minutes.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_layer_version_by_arn)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_layer_version_by_arn)
        """

    def get_layer_version_policy(
        self, **kwargs: Unpack[GetLayerVersionPolicyRequestRequestTypeDef]
    ) -> GetLayerVersionPolicyResponseTypeDef:
        """
        Returns the permission policy for a version of an [Lambda
        layer](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_layer_version_policy)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_layer_version_policy)
        """

    def get_policy(
        self, **kwargs: Unpack[GetPolicyRequestRequestTypeDef]
    ) -> GetPolicyResponseTypeDef:
        """
        Returns the [resource-based IAM
        policy](https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html)
        for a function, version, or
        alias.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_policy)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_policy)
        """

    def get_provisioned_concurrency_config(
        self, **kwargs: Unpack[GetProvisionedConcurrencyConfigRequestRequestTypeDef]
    ) -> GetProvisionedConcurrencyConfigResponseTypeDef:
        """
        Retrieves the provisioned concurrency configuration for a function's alias or
        version.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_provisioned_concurrency_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_provisioned_concurrency_config)
        """

    def get_runtime_management_config(
        self, **kwargs: Unpack[GetRuntimeManagementConfigRequestRequestTypeDef]
    ) -> GetRuntimeManagementConfigResponseTypeDef:
        """
        Retrieves the runtime management configuration for a function's version.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_runtime_management_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_runtime_management_config)
        """

    def invoke(
        self, **kwargs: Unpack[InvocationRequestRequestTypeDef]
    ) -> InvocationResponseTypeDef:
        """
        Invokes a Lambda function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.invoke)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#invoke)
        """

    def invoke_async(
        self, **kwargs: Unpack[InvokeAsyncRequestRequestTypeDef]
    ) -> InvokeAsyncResponseTypeDef:
        """
        .

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.invoke_async)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#invoke_async)
        """

    def invoke_with_response_stream(
        self, **kwargs: Unpack[InvokeWithResponseStreamRequestRequestTypeDef]
    ) -> InvokeWithResponseStreamResponseTypeDef:
        """
        Configure your Lambda functions to stream response payloads back to clients.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.invoke_with_response_stream)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#invoke_with_response_stream)
        """

    def list_aliases(
        self, **kwargs: Unpack[ListAliasesRequestRequestTypeDef]
    ) -> ListAliasesResponseTypeDef:
        """
        Returns a list of
        [aliases](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html)
        for a Lambda
        function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_aliases)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_aliases)
        """

    def list_code_signing_configs(
        self, **kwargs: Unpack[ListCodeSigningConfigsRequestRequestTypeDef]
    ) -> ListCodeSigningConfigsResponseTypeDef:
        """
        Returns a list of [code signing
        configurations](https://docs.aws.amazon.com/lambda/latest/dg/configuring-codesigning.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_code_signing_configs)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_code_signing_configs)
        """

    def list_event_source_mappings(
        self, **kwargs: Unpack[ListEventSourceMappingsRequestRequestTypeDef]
    ) -> ListEventSourceMappingsResponseTypeDef:
        """
        Lists event source mappings.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_event_source_mappings)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_event_source_mappings)
        """

    def list_function_event_invoke_configs(
        self, **kwargs: Unpack[ListFunctionEventInvokeConfigsRequestRequestTypeDef]
    ) -> ListFunctionEventInvokeConfigsResponseTypeDef:
        """
        Retrieves a list of configurations for asynchronous invocation for a function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_function_event_invoke_configs)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_function_event_invoke_configs)
        """

    def list_function_url_configs(
        self, **kwargs: Unpack[ListFunctionUrlConfigsRequestRequestTypeDef]
    ) -> ListFunctionUrlConfigsResponseTypeDef:
        """
        Returns a list of Lambda function URLs for the specified function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_function_url_configs)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_function_url_configs)
        """

    def list_functions(
        self, **kwargs: Unpack[ListFunctionsRequestRequestTypeDef]
    ) -> ListFunctionsResponseTypeDef:
        """
        Returns a list of Lambda functions, with the version-specific configuration of
        each.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_functions)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_functions)
        """

    def list_functions_by_code_signing_config(
        self, **kwargs: Unpack[ListFunctionsByCodeSigningConfigRequestRequestTypeDef]
    ) -> ListFunctionsByCodeSigningConfigResponseTypeDef:
        """
        List the functions that use the specified code signing configuration.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_functions_by_code_signing_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_functions_by_code_signing_config)
        """

    def list_layer_versions(
        self, **kwargs: Unpack[ListLayerVersionsRequestRequestTypeDef]
    ) -> ListLayerVersionsResponseTypeDef:
        """
        Lists the versions of an [Lambda
        layer](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_layer_versions)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_layer_versions)
        """

    def list_layers(
        self, **kwargs: Unpack[ListLayersRequestRequestTypeDef]
    ) -> ListLayersResponseTypeDef:
        """
        Lists [Lambda
        layers](https://docs.aws.amazon.com/lambda/latest/dg/invocation-layers.html)
        and shows information about the latest version of
        each.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_layers)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_layers)
        """

    def list_provisioned_concurrency_configs(
        self, **kwargs: Unpack[ListProvisionedConcurrencyConfigsRequestRequestTypeDef]
    ) -> ListProvisionedConcurrencyConfigsResponseTypeDef:
        """
        Retrieves a list of provisioned concurrency configurations for a function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_provisioned_concurrency_configs)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_provisioned_concurrency_configs)
        """

    def list_tags(self, **kwargs: Unpack[ListTagsRequestRequestTypeDef]) -> ListTagsResponseTypeDef:
        """
        Returns a function, event source mapping, or code signing configuration's
        [tags](https://docs.aws.amazon.com/lambda/latest/dg/tagging.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_tags)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_tags)
        """

    def list_versions_by_function(
        self, **kwargs: Unpack[ListVersionsByFunctionRequestRequestTypeDef]
    ) -> ListVersionsByFunctionResponseTypeDef:
        """
        Returns a list of
        [versions](https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html),
        with the version-specific configuration of
        each.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.list_versions_by_function)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#list_versions_by_function)
        """

    def publish_layer_version(
        self, **kwargs: Unpack[PublishLayerVersionRequestRequestTypeDef]
    ) -> PublishLayerVersionResponseTypeDef:
        """
        Creates an [Lambda
        layer](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html)
        from a ZIP
        archive.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.publish_layer_version)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#publish_layer_version)
        """

    def publish_version(
        self, **kwargs: Unpack[PublishVersionRequestRequestTypeDef]
    ) -> FunctionConfigurationResponseTypeDef:
        """
        Creates a
        [version](https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html)
        from the current code and configuration of a
        function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.publish_version)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#publish_version)
        """

    def put_function_code_signing_config(
        self, **kwargs: Unpack[PutFunctionCodeSigningConfigRequestRequestTypeDef]
    ) -> PutFunctionCodeSigningConfigResponseTypeDef:
        """
        Update the code signing configuration for the function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.put_function_code_signing_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#put_function_code_signing_config)
        """

    def put_function_concurrency(
        self, **kwargs: Unpack[PutFunctionConcurrencyRequestRequestTypeDef]
    ) -> ConcurrencyResponseTypeDef:
        """
        Sets the maximum number of simultaneous executions for a function, and reserves
        capacity for that concurrency
        level.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.put_function_concurrency)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#put_function_concurrency)
        """

    def put_function_event_invoke_config(
        self, **kwargs: Unpack[PutFunctionEventInvokeConfigRequestRequestTypeDef]
    ) -> FunctionEventInvokeConfigResponseTypeDef:
        """
        Configures options for [asynchronous
        invocation](https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html)
        on a function, version, or
        alias.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.put_function_event_invoke_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#put_function_event_invoke_config)
        """

    def put_function_recursion_config(
        self, **kwargs: Unpack[PutFunctionRecursionConfigRequestRequestTypeDef]
    ) -> PutFunctionRecursionConfigResponseTypeDef:
        """
        Sets your function's [recursive loop
        detection](https://docs.aws.amazon.com/lambda/latest/dg/invocation-recursion.html)
        configuration.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.put_function_recursion_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#put_function_recursion_config)
        """

    def put_provisioned_concurrency_config(
        self, **kwargs: Unpack[PutProvisionedConcurrencyConfigRequestRequestTypeDef]
    ) -> PutProvisionedConcurrencyConfigResponseTypeDef:
        """
        Adds a provisioned concurrency configuration to a function's alias or version.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.put_provisioned_concurrency_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#put_provisioned_concurrency_config)
        """

    def put_runtime_management_config(
        self, **kwargs: Unpack[PutRuntimeManagementConfigRequestRequestTypeDef]
    ) -> PutRuntimeManagementConfigResponseTypeDef:
        """
        Sets the runtime management configuration for a function's version.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.put_runtime_management_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#put_runtime_management_config)
        """

    def remove_layer_version_permission(
        self, **kwargs: Unpack[RemoveLayerVersionPermissionRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Removes a statement from the permissions policy for a version of an [Lambda
        layer](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.remove_layer_version_permission)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#remove_layer_version_permission)
        """

    def remove_permission(
        self, **kwargs: Unpack[RemovePermissionRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Revokes function-use permission from an Amazon Web Services service or another
        Amazon Web Services
        account.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.remove_permission)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#remove_permission)
        """

    def tag_resource(
        self, **kwargs: Unpack[TagResourceRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Adds [tags](https://docs.aws.amazon.com/lambda/latest/dg/tagging.html) to a
        function, event source mapping, or code signing
        configuration.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.tag_resource)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#tag_resource)
        """

    def untag_resource(
        self, **kwargs: Unpack[UntagResourceRequestRequestTypeDef]
    ) -> EmptyResponseMetadataTypeDef:
        """
        Removes [tags](https://docs.aws.amazon.com/lambda/latest/dg/tagging.html) from
        a function, event source mapping, or code signing
        configuration.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.untag_resource)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#untag_resource)
        """

    def update_alias(
        self, **kwargs: Unpack[UpdateAliasRequestRequestTypeDef]
    ) -> AliasConfigurationResponseTypeDef:
        """
        Updates the configuration of a Lambda function
        [alias](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html).

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.update_alias)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#update_alias)
        """

    def update_code_signing_config(
        self, **kwargs: Unpack[UpdateCodeSigningConfigRequestRequestTypeDef]
    ) -> UpdateCodeSigningConfigResponseTypeDef:
        """
        Update the code signing configuration.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.update_code_signing_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#update_code_signing_config)
        """

    def update_event_source_mapping(
        self, **kwargs: Unpack[UpdateEventSourceMappingRequestRequestTypeDef]
    ) -> EventSourceMappingConfigurationResponseTypeDef:
        """
        Updates an event source mapping.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.update_event_source_mapping)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#update_event_source_mapping)
        """

    def update_function_code(
        self, **kwargs: Unpack[UpdateFunctionCodeRequestRequestTypeDef]
    ) -> FunctionConfigurationResponseTypeDef:
        """
        Updates a Lambda function's code.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.update_function_code)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#update_function_code)
        """

    def update_function_configuration(
        self, **kwargs: Unpack[UpdateFunctionConfigurationRequestRequestTypeDef]
    ) -> FunctionConfigurationResponseTypeDef:
        """
        Modify the version-specific settings of a Lambda function.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.update_function_configuration)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#update_function_configuration)
        """

    def update_function_event_invoke_config(
        self, **kwargs: Unpack[UpdateFunctionEventInvokeConfigRequestRequestTypeDef]
    ) -> FunctionEventInvokeConfigResponseTypeDef:
        """
        Updates the configuration for asynchronous invocation for a function, version,
        or
        alias.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.update_function_event_invoke_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#update_function_event_invoke_config)
        """

    def update_function_url_config(
        self, **kwargs: Unpack[UpdateFunctionUrlConfigRequestRequestTypeDef]
    ) -> UpdateFunctionUrlConfigResponseTypeDef:
        """
        Updates the configuration for a Lambda function URL.

        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.update_function_url_config)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#update_function_url_config)
        """

    @overload
    def get_paginator(self, operation_name: Literal["list_aliases"]) -> ListAliasesPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_paginator(
        self, operation_name: Literal["list_code_signing_configs"]
    ) -> ListCodeSigningConfigsPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_paginator(
        self, operation_name: Literal["list_event_source_mappings"]
    ) -> ListEventSourceMappingsPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_paginator(
        self, operation_name: Literal["list_function_event_invoke_configs"]
    ) -> ListFunctionEventInvokeConfigsPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_paginator(
        self, operation_name: Literal["list_function_url_configs"]
    ) -> ListFunctionUrlConfigsPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_paginator(self, operation_name: Literal["list_functions"]) -> ListFunctionsPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_paginator(
        self, operation_name: Literal["list_functions_by_code_signing_config"]
    ) -> ListFunctionsByCodeSigningConfigPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_paginator(
        self, operation_name: Literal["list_layer_versions"]
    ) -> ListLayerVersionsPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_paginator(self, operation_name: Literal["list_layers"]) -> ListLayersPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_paginator(
        self, operation_name: Literal["list_provisioned_concurrency_configs"]
    ) -> ListProvisionedConcurrencyConfigsPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_paginator(
        self, operation_name: Literal["list_versions_by_function"]
    ) -> ListVersionsByFunctionPaginator:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_paginator)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_paginator)
        """

    @overload
    def get_waiter(self, waiter_name: Literal["function_active"]) -> FunctionActiveWaiter:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_waiter)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_waiter)
        """

    @overload
    def get_waiter(self, waiter_name: Literal["function_active_v2"]) -> FunctionActiveV2Waiter:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_waiter)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_waiter)
        """

    @overload
    def get_waiter(self, waiter_name: Literal["function_exists"]) -> FunctionExistsWaiter:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_waiter)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_waiter)
        """

    @overload
    def get_waiter(self, waiter_name: Literal["function_updated"]) -> FunctionUpdatedWaiter:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_waiter)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_waiter)
        """

    @overload
    def get_waiter(self, waiter_name: Literal["function_updated_v2"]) -> FunctionUpdatedV2Waiter:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_waiter)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_waiter)
        """

    @overload
    def get_waiter(
        self, waiter_name: Literal["published_version_active"]
    ) -> PublishedVersionActiveWaiter:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Client.get_waiter)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/client/#get_waiter)
        """
