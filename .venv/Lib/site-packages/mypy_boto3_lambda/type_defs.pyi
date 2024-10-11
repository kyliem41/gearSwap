"""
Type annotations for lambda service type definitions.

[Open documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/type_defs/)

Usage::

    ```python
    from mypy_boto3_lambda.type_defs import AccountLimitTypeDef

    data: AccountLimitTypeDef = ...
    ```
"""

import sys
from datetime import datetime
from typing import IO, Any, Dict, List, Mapping, Sequence, Union

from botocore.eventstream import EventStream
from botocore.response import StreamingBody

from .literals import (
    ApplicationLogLevelType,
    ArchitectureType,
    CodeSigningPolicyType,
    EventSourcePositionType,
    FullDocumentType,
    FunctionUrlAuthTypeType,
    InvocationTypeType,
    InvokeModeType,
    LastUpdateStatusReasonCodeType,
    LastUpdateStatusType,
    LogFormatType,
    LogTypeType,
    PackageTypeType,
    ProvisionedConcurrencyStatusEnumType,
    RecursiveLoopType,
    ResponseStreamingInvocationTypeType,
    RuntimeType,
    SnapStartApplyOnType,
    SnapStartOptimizationStatusType,
    SourceAccessTypeType,
    StateReasonCodeType,
    StateType,
    SystemLogLevelType,
    TracingModeType,
    UpdateRuntimeOnType,
)

if sys.version_info >= (3, 12):
    from typing import Literal, NotRequired, TypedDict
else:
    from typing_extensions import Literal, NotRequired, TypedDict

__all__ = (
    "AccountLimitTypeDef",
    "AccountUsageTypeDef",
    "AddLayerVersionPermissionRequestRequestTypeDef",
    "ResponseMetadataTypeDef",
    "AddPermissionRequestRequestTypeDef",
    "AliasRoutingConfigurationOutputTypeDef",
    "AliasRoutingConfigurationTypeDef",
    "AllowedPublishersOutputTypeDef",
    "AllowedPublishersTypeDef",
    "AmazonManagedKafkaEventSourceConfigTypeDef",
    "BlobTypeDef",
    "CodeSigningPoliciesTypeDef",
    "ConcurrencyTypeDef",
    "CorsOutputTypeDef",
    "CorsTypeDef",
    "DocumentDBEventSourceConfigTypeDef",
    "ScalingConfigTypeDef",
    "SelfManagedEventSourceTypeDef",
    "SelfManagedKafkaEventSourceConfigTypeDef",
    "SourceAccessConfigurationTypeDef",
    "TimestampTypeDef",
    "DeadLetterConfigTypeDef",
    "EnvironmentTypeDef",
    "EphemeralStorageTypeDef",
    "FileSystemConfigTypeDef",
    "ImageConfigTypeDef",
    "LoggingConfigTypeDef",
    "SnapStartTypeDef",
    "TracingConfigTypeDef",
    "VpcConfigTypeDef",
    "DeleteAliasRequestRequestTypeDef",
    "DeleteCodeSigningConfigRequestRequestTypeDef",
    "DeleteEventSourceMappingRequestRequestTypeDef",
    "DeleteFunctionCodeSigningConfigRequestRequestTypeDef",
    "DeleteFunctionConcurrencyRequestRequestTypeDef",
    "DeleteFunctionEventInvokeConfigRequestRequestTypeDef",
    "DeleteFunctionRequestRequestTypeDef",
    "DeleteFunctionUrlConfigRequestRequestTypeDef",
    "DeleteLayerVersionRequestRequestTypeDef",
    "DeleteProvisionedConcurrencyConfigRequestRequestTypeDef",
    "OnFailureTypeDef",
    "OnSuccessTypeDef",
    "EnvironmentErrorTypeDef",
    "FilterCriteriaErrorTypeDef",
    "SelfManagedEventSourceOutputTypeDef",
    "FilterTypeDef",
    "FunctionCodeLocationTypeDef",
    "LayerTypeDef",
    "SnapStartResponseTypeDef",
    "TracingConfigResponseTypeDef",
    "VpcConfigResponseTypeDef",
    "GetAliasRequestRequestTypeDef",
    "GetCodeSigningConfigRequestRequestTypeDef",
    "GetEventSourceMappingRequestRequestTypeDef",
    "GetFunctionCodeSigningConfigRequestRequestTypeDef",
    "GetFunctionConcurrencyRequestRequestTypeDef",
    "WaiterConfigTypeDef",
    "GetFunctionConfigurationRequestRequestTypeDef",
    "GetFunctionEventInvokeConfigRequestRequestTypeDef",
    "GetFunctionRecursionConfigRequestRequestTypeDef",
    "GetFunctionRequestRequestTypeDef",
    "GetFunctionUrlConfigRequestRequestTypeDef",
    "GetLayerVersionByArnRequestRequestTypeDef",
    "GetLayerVersionPolicyRequestRequestTypeDef",
    "GetLayerVersionRequestRequestTypeDef",
    "LayerVersionContentOutputTypeDef",
    "GetPolicyRequestRequestTypeDef",
    "GetProvisionedConcurrencyConfigRequestRequestTypeDef",
    "GetRuntimeManagementConfigRequestRequestTypeDef",
    "ImageConfigErrorTypeDef",
    "ImageConfigOutputTypeDef",
    "InvokeResponseStreamUpdateTypeDef",
    "InvokeWithResponseStreamCompleteEventTypeDef",
    "LayerVersionsListItemTypeDef",
    "PaginatorConfigTypeDef",
    "ListAliasesRequestRequestTypeDef",
    "ListCodeSigningConfigsRequestRequestTypeDef",
    "ListEventSourceMappingsRequestRequestTypeDef",
    "ListFunctionEventInvokeConfigsRequestRequestTypeDef",
    "ListFunctionUrlConfigsRequestRequestTypeDef",
    "ListFunctionsByCodeSigningConfigRequestRequestTypeDef",
    "ListFunctionsRequestRequestTypeDef",
    "ListLayerVersionsRequestRequestTypeDef",
    "ListLayersRequestRequestTypeDef",
    "ListProvisionedConcurrencyConfigsRequestRequestTypeDef",
    "ProvisionedConcurrencyConfigListItemTypeDef",
    "ListTagsRequestRequestTypeDef",
    "ListVersionsByFunctionRequestRequestTypeDef",
    "PublishVersionRequestRequestTypeDef",
    "PutFunctionCodeSigningConfigRequestRequestTypeDef",
    "PutFunctionConcurrencyRequestRequestTypeDef",
    "PutFunctionRecursionConfigRequestRequestTypeDef",
    "PutProvisionedConcurrencyConfigRequestRequestTypeDef",
    "PutRuntimeManagementConfigRequestRequestTypeDef",
    "RemoveLayerVersionPermissionRequestRequestTypeDef",
    "RemovePermissionRequestRequestTypeDef",
    "RuntimeVersionErrorTypeDef",
    "TagResourceRequestRequestTypeDef",
    "UntagResourceRequestRequestTypeDef",
    "AddLayerVersionPermissionResponseTypeDef",
    "AddPermissionResponseTypeDef",
    "ConcurrencyResponseTypeDef",
    "EmptyResponseMetadataTypeDef",
    "GetAccountSettingsResponseTypeDef",
    "GetFunctionCodeSigningConfigResponseTypeDef",
    "GetFunctionConcurrencyResponseTypeDef",
    "GetFunctionRecursionConfigResponseTypeDef",
    "GetLayerVersionPolicyResponseTypeDef",
    "GetPolicyResponseTypeDef",
    "GetProvisionedConcurrencyConfigResponseTypeDef",
    "GetRuntimeManagementConfigResponseTypeDef",
    "InvocationResponseTypeDef",
    "InvokeAsyncResponseTypeDef",
    "ListFunctionsByCodeSigningConfigResponseTypeDef",
    "ListTagsResponseTypeDef",
    "PutFunctionCodeSigningConfigResponseTypeDef",
    "PutFunctionRecursionConfigResponseTypeDef",
    "PutProvisionedConcurrencyConfigResponseTypeDef",
    "PutRuntimeManagementConfigResponseTypeDef",
    "AliasConfigurationResponseTypeDef",
    "AliasConfigurationTypeDef",
    "CreateAliasRequestRequestTypeDef",
    "UpdateAliasRequestRequestTypeDef",
    "FunctionCodeTypeDef",
    "InvocationRequestRequestTypeDef",
    "InvokeAsyncRequestRequestTypeDef",
    "InvokeWithResponseStreamRequestRequestTypeDef",
    "LayerVersionContentInputTypeDef",
    "UpdateFunctionCodeRequestRequestTypeDef",
    "CodeSigningConfigTypeDef",
    "CreateCodeSigningConfigRequestRequestTypeDef",
    "UpdateCodeSigningConfigRequestRequestTypeDef",
    "CreateFunctionUrlConfigResponseTypeDef",
    "FunctionUrlConfigTypeDef",
    "GetFunctionUrlConfigResponseTypeDef",
    "UpdateFunctionUrlConfigResponseTypeDef",
    "CreateFunctionUrlConfigRequestRequestTypeDef",
    "UpdateFunctionUrlConfigRequestRequestTypeDef",
    "UpdateFunctionConfigurationRequestRequestTypeDef",
    "DestinationConfigTypeDef",
    "EnvironmentResponseTypeDef",
    "FilterCriteriaOutputTypeDef",
    "FilterCriteriaTypeDef",
    "GetFunctionConfigurationRequestFunctionActiveWaitTypeDef",
    "GetFunctionConfigurationRequestFunctionUpdatedWaitTypeDef",
    "GetFunctionConfigurationRequestPublishedVersionActiveWaitTypeDef",
    "GetFunctionRequestFunctionActiveV2WaitTypeDef",
    "GetFunctionRequestFunctionExistsWaitTypeDef",
    "GetFunctionRequestFunctionUpdatedV2WaitTypeDef",
    "GetLayerVersionResponseTypeDef",
    "PublishLayerVersionResponseTypeDef",
    "ImageConfigResponseTypeDef",
    "InvokeWithResponseStreamResponseEventTypeDef",
    "LayersListItemTypeDef",
    "ListLayerVersionsResponseTypeDef",
    "ListAliasesRequestListAliasesPaginateTypeDef",
    "ListCodeSigningConfigsRequestListCodeSigningConfigsPaginateTypeDef",
    "ListEventSourceMappingsRequestListEventSourceMappingsPaginateTypeDef",
    "ListFunctionEventInvokeConfigsRequestListFunctionEventInvokeConfigsPaginateTypeDef",
    "ListFunctionUrlConfigsRequestListFunctionUrlConfigsPaginateTypeDef",
    "ListFunctionsByCodeSigningConfigRequestListFunctionsByCodeSigningConfigPaginateTypeDef",
    "ListFunctionsRequestListFunctionsPaginateTypeDef",
    "ListLayerVersionsRequestListLayerVersionsPaginateTypeDef",
    "ListLayersRequestListLayersPaginateTypeDef",
    "ListProvisionedConcurrencyConfigsRequestListProvisionedConcurrencyConfigsPaginateTypeDef",
    "ListVersionsByFunctionRequestListVersionsByFunctionPaginateTypeDef",
    "ListProvisionedConcurrencyConfigsResponseTypeDef",
    "RuntimeVersionConfigTypeDef",
    "ListAliasesResponseTypeDef",
    "CreateFunctionRequestRequestTypeDef",
    "PublishLayerVersionRequestRequestTypeDef",
    "CreateCodeSigningConfigResponseTypeDef",
    "GetCodeSigningConfigResponseTypeDef",
    "ListCodeSigningConfigsResponseTypeDef",
    "UpdateCodeSigningConfigResponseTypeDef",
    "ListFunctionUrlConfigsResponseTypeDef",
    "FunctionEventInvokeConfigResponseTypeDef",
    "FunctionEventInvokeConfigTypeDef",
    "PutFunctionEventInvokeConfigRequestRequestTypeDef",
    "UpdateFunctionEventInvokeConfigRequestRequestTypeDef",
    "EventSourceMappingConfigurationResponseTypeDef",
    "EventSourceMappingConfigurationTypeDef",
    "CreateEventSourceMappingRequestRequestTypeDef",
    "UpdateEventSourceMappingRequestRequestTypeDef",
    "InvokeWithResponseStreamResponseTypeDef",
    "ListLayersResponseTypeDef",
    "FunctionConfigurationResponseTypeDef",
    "FunctionConfigurationTypeDef",
    "ListFunctionEventInvokeConfigsResponseTypeDef",
    "ListEventSourceMappingsResponseTypeDef",
    "GetFunctionResponseTypeDef",
    "ListFunctionsResponseTypeDef",
    "ListVersionsByFunctionResponseTypeDef",
)

AccountLimitTypeDef = TypedDict(
    "AccountLimitTypeDef",
    {
        "TotalCodeSize": NotRequired[int],
        "CodeSizeUnzipped": NotRequired[int],
        "CodeSizeZipped": NotRequired[int],
        "ConcurrentExecutions": NotRequired[int],
        "UnreservedConcurrentExecutions": NotRequired[int],
    },
)
AccountUsageTypeDef = TypedDict(
    "AccountUsageTypeDef",
    {
        "TotalCodeSize": NotRequired[int],
        "FunctionCount": NotRequired[int],
    },
)
AddLayerVersionPermissionRequestRequestTypeDef = TypedDict(
    "AddLayerVersionPermissionRequestRequestTypeDef",
    {
        "LayerName": str,
        "VersionNumber": int,
        "StatementId": str,
        "Action": str,
        "Principal": str,
        "OrganizationId": NotRequired[str],
        "RevisionId": NotRequired[str],
    },
)
ResponseMetadataTypeDef = TypedDict(
    "ResponseMetadataTypeDef",
    {
        "RequestId": str,
        "HTTPStatusCode": int,
        "HTTPHeaders": Dict[str, str],
        "RetryAttempts": int,
        "HostId": NotRequired[str],
    },
)
AddPermissionRequestRequestTypeDef = TypedDict(
    "AddPermissionRequestRequestTypeDef",
    {
        "FunctionName": str,
        "StatementId": str,
        "Action": str,
        "Principal": str,
        "SourceArn": NotRequired[str],
        "SourceAccount": NotRequired[str],
        "EventSourceToken": NotRequired[str],
        "Qualifier": NotRequired[str],
        "RevisionId": NotRequired[str],
        "PrincipalOrgID": NotRequired[str],
        "FunctionUrlAuthType": NotRequired[FunctionUrlAuthTypeType],
    },
)
AliasRoutingConfigurationOutputTypeDef = TypedDict(
    "AliasRoutingConfigurationOutputTypeDef",
    {
        "AdditionalVersionWeights": NotRequired[Dict[str, float]],
    },
)
AliasRoutingConfigurationTypeDef = TypedDict(
    "AliasRoutingConfigurationTypeDef",
    {
        "AdditionalVersionWeights": NotRequired[Mapping[str, float]],
    },
)
AllowedPublishersOutputTypeDef = TypedDict(
    "AllowedPublishersOutputTypeDef",
    {
        "SigningProfileVersionArns": List[str],
    },
)
AllowedPublishersTypeDef = TypedDict(
    "AllowedPublishersTypeDef",
    {
        "SigningProfileVersionArns": Sequence[str],
    },
)
AmazonManagedKafkaEventSourceConfigTypeDef = TypedDict(
    "AmazonManagedKafkaEventSourceConfigTypeDef",
    {
        "ConsumerGroupId": NotRequired[str],
    },
)
BlobTypeDef = Union[str, bytes, IO[Any], StreamingBody]
CodeSigningPoliciesTypeDef = TypedDict(
    "CodeSigningPoliciesTypeDef",
    {
        "UntrustedArtifactOnDeployment": NotRequired[CodeSigningPolicyType],
    },
)
ConcurrencyTypeDef = TypedDict(
    "ConcurrencyTypeDef",
    {
        "ReservedConcurrentExecutions": NotRequired[int],
    },
)
CorsOutputTypeDef = TypedDict(
    "CorsOutputTypeDef",
    {
        "AllowCredentials": NotRequired[bool],
        "AllowHeaders": NotRequired[List[str]],
        "AllowMethods": NotRequired[List[str]],
        "AllowOrigins": NotRequired[List[str]],
        "ExposeHeaders": NotRequired[List[str]],
        "MaxAge": NotRequired[int],
    },
)
CorsTypeDef = TypedDict(
    "CorsTypeDef",
    {
        "AllowCredentials": NotRequired[bool],
        "AllowHeaders": NotRequired[Sequence[str]],
        "AllowMethods": NotRequired[Sequence[str]],
        "AllowOrigins": NotRequired[Sequence[str]],
        "ExposeHeaders": NotRequired[Sequence[str]],
        "MaxAge": NotRequired[int],
    },
)
DocumentDBEventSourceConfigTypeDef = TypedDict(
    "DocumentDBEventSourceConfigTypeDef",
    {
        "DatabaseName": NotRequired[str],
        "CollectionName": NotRequired[str],
        "FullDocument": NotRequired[FullDocumentType],
    },
)
ScalingConfigTypeDef = TypedDict(
    "ScalingConfigTypeDef",
    {
        "MaximumConcurrency": NotRequired[int],
    },
)
SelfManagedEventSourceTypeDef = TypedDict(
    "SelfManagedEventSourceTypeDef",
    {
        "Endpoints": NotRequired[Mapping[Literal["KAFKA_BOOTSTRAP_SERVERS"], Sequence[str]]],
    },
)
SelfManagedKafkaEventSourceConfigTypeDef = TypedDict(
    "SelfManagedKafkaEventSourceConfigTypeDef",
    {
        "ConsumerGroupId": NotRequired[str],
    },
)
SourceAccessConfigurationTypeDef = TypedDict(
    "SourceAccessConfigurationTypeDef",
    {
        "Type": NotRequired[SourceAccessTypeType],
        "URI": NotRequired[str],
    },
)
TimestampTypeDef = Union[datetime, str]
DeadLetterConfigTypeDef = TypedDict(
    "DeadLetterConfigTypeDef",
    {
        "TargetArn": NotRequired[str],
    },
)
EnvironmentTypeDef = TypedDict(
    "EnvironmentTypeDef",
    {
        "Variables": NotRequired[Mapping[str, str]],
    },
)
EphemeralStorageTypeDef = TypedDict(
    "EphemeralStorageTypeDef",
    {
        "Size": int,
    },
)
FileSystemConfigTypeDef = TypedDict(
    "FileSystemConfigTypeDef",
    {
        "Arn": str,
        "LocalMountPath": str,
    },
)
ImageConfigTypeDef = TypedDict(
    "ImageConfigTypeDef",
    {
        "EntryPoint": NotRequired[Sequence[str]],
        "Command": NotRequired[Sequence[str]],
        "WorkingDirectory": NotRequired[str],
    },
)
LoggingConfigTypeDef = TypedDict(
    "LoggingConfigTypeDef",
    {
        "LogFormat": NotRequired[LogFormatType],
        "ApplicationLogLevel": NotRequired[ApplicationLogLevelType],
        "SystemLogLevel": NotRequired[SystemLogLevelType],
        "LogGroup": NotRequired[str],
    },
)
SnapStartTypeDef = TypedDict(
    "SnapStartTypeDef",
    {
        "ApplyOn": NotRequired[SnapStartApplyOnType],
    },
)
TracingConfigTypeDef = TypedDict(
    "TracingConfigTypeDef",
    {
        "Mode": NotRequired[TracingModeType],
    },
)
VpcConfigTypeDef = TypedDict(
    "VpcConfigTypeDef",
    {
        "SubnetIds": NotRequired[Sequence[str]],
        "SecurityGroupIds": NotRequired[Sequence[str]],
        "Ipv6AllowedForDualStack": NotRequired[bool],
    },
)
DeleteAliasRequestRequestTypeDef = TypedDict(
    "DeleteAliasRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Name": str,
    },
)
DeleteCodeSigningConfigRequestRequestTypeDef = TypedDict(
    "DeleteCodeSigningConfigRequestRequestTypeDef",
    {
        "CodeSigningConfigArn": str,
    },
)
DeleteEventSourceMappingRequestRequestTypeDef = TypedDict(
    "DeleteEventSourceMappingRequestRequestTypeDef",
    {
        "UUID": str,
    },
)
DeleteFunctionCodeSigningConfigRequestRequestTypeDef = TypedDict(
    "DeleteFunctionCodeSigningConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
    },
)
DeleteFunctionConcurrencyRequestRequestTypeDef = TypedDict(
    "DeleteFunctionConcurrencyRequestRequestTypeDef",
    {
        "FunctionName": str,
    },
)
DeleteFunctionEventInvokeConfigRequestRequestTypeDef = TypedDict(
    "DeleteFunctionEventInvokeConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
    },
)
DeleteFunctionRequestRequestTypeDef = TypedDict(
    "DeleteFunctionRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
    },
)
DeleteFunctionUrlConfigRequestRequestTypeDef = TypedDict(
    "DeleteFunctionUrlConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
    },
)
DeleteLayerVersionRequestRequestTypeDef = TypedDict(
    "DeleteLayerVersionRequestRequestTypeDef",
    {
        "LayerName": str,
        "VersionNumber": int,
    },
)
DeleteProvisionedConcurrencyConfigRequestRequestTypeDef = TypedDict(
    "DeleteProvisionedConcurrencyConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": str,
    },
)
OnFailureTypeDef = TypedDict(
    "OnFailureTypeDef",
    {
        "Destination": NotRequired[str],
    },
)
OnSuccessTypeDef = TypedDict(
    "OnSuccessTypeDef",
    {
        "Destination": NotRequired[str],
    },
)
EnvironmentErrorTypeDef = TypedDict(
    "EnvironmentErrorTypeDef",
    {
        "ErrorCode": NotRequired[str],
        "Message": NotRequired[str],
    },
)
FilterCriteriaErrorTypeDef = TypedDict(
    "FilterCriteriaErrorTypeDef",
    {
        "ErrorCode": NotRequired[str],
        "Message": NotRequired[str],
    },
)
SelfManagedEventSourceOutputTypeDef = TypedDict(
    "SelfManagedEventSourceOutputTypeDef",
    {
        "Endpoints": NotRequired[Dict[Literal["KAFKA_BOOTSTRAP_SERVERS"], List[str]]],
    },
)
FilterTypeDef = TypedDict(
    "FilterTypeDef",
    {
        "Pattern": NotRequired[str],
    },
)
FunctionCodeLocationTypeDef = TypedDict(
    "FunctionCodeLocationTypeDef",
    {
        "RepositoryType": NotRequired[str],
        "Location": NotRequired[str],
        "ImageUri": NotRequired[str],
        "ResolvedImageUri": NotRequired[str],
    },
)
LayerTypeDef = TypedDict(
    "LayerTypeDef",
    {
        "Arn": NotRequired[str],
        "CodeSize": NotRequired[int],
        "SigningProfileVersionArn": NotRequired[str],
        "SigningJobArn": NotRequired[str],
    },
)
SnapStartResponseTypeDef = TypedDict(
    "SnapStartResponseTypeDef",
    {
        "ApplyOn": NotRequired[SnapStartApplyOnType],
        "OptimizationStatus": NotRequired[SnapStartOptimizationStatusType],
    },
)
TracingConfigResponseTypeDef = TypedDict(
    "TracingConfigResponseTypeDef",
    {
        "Mode": NotRequired[TracingModeType],
    },
)
VpcConfigResponseTypeDef = TypedDict(
    "VpcConfigResponseTypeDef",
    {
        "SubnetIds": NotRequired[List[str]],
        "SecurityGroupIds": NotRequired[List[str]],
        "VpcId": NotRequired[str],
        "Ipv6AllowedForDualStack": NotRequired[bool],
    },
)
GetAliasRequestRequestTypeDef = TypedDict(
    "GetAliasRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Name": str,
    },
)
GetCodeSigningConfigRequestRequestTypeDef = TypedDict(
    "GetCodeSigningConfigRequestRequestTypeDef",
    {
        "CodeSigningConfigArn": str,
    },
)
GetEventSourceMappingRequestRequestTypeDef = TypedDict(
    "GetEventSourceMappingRequestRequestTypeDef",
    {
        "UUID": str,
    },
)
GetFunctionCodeSigningConfigRequestRequestTypeDef = TypedDict(
    "GetFunctionCodeSigningConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
    },
)
GetFunctionConcurrencyRequestRequestTypeDef = TypedDict(
    "GetFunctionConcurrencyRequestRequestTypeDef",
    {
        "FunctionName": str,
    },
)
WaiterConfigTypeDef = TypedDict(
    "WaiterConfigTypeDef",
    {
        "Delay": NotRequired[int],
        "MaxAttempts": NotRequired[int],
    },
)
GetFunctionConfigurationRequestRequestTypeDef = TypedDict(
    "GetFunctionConfigurationRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
    },
)
GetFunctionEventInvokeConfigRequestRequestTypeDef = TypedDict(
    "GetFunctionEventInvokeConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
    },
)
GetFunctionRecursionConfigRequestRequestTypeDef = TypedDict(
    "GetFunctionRecursionConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
    },
)
GetFunctionRequestRequestTypeDef = TypedDict(
    "GetFunctionRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
    },
)
GetFunctionUrlConfigRequestRequestTypeDef = TypedDict(
    "GetFunctionUrlConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
    },
)
GetLayerVersionByArnRequestRequestTypeDef = TypedDict(
    "GetLayerVersionByArnRequestRequestTypeDef",
    {
        "Arn": str,
    },
)
GetLayerVersionPolicyRequestRequestTypeDef = TypedDict(
    "GetLayerVersionPolicyRequestRequestTypeDef",
    {
        "LayerName": str,
        "VersionNumber": int,
    },
)
GetLayerVersionRequestRequestTypeDef = TypedDict(
    "GetLayerVersionRequestRequestTypeDef",
    {
        "LayerName": str,
        "VersionNumber": int,
    },
)
LayerVersionContentOutputTypeDef = TypedDict(
    "LayerVersionContentOutputTypeDef",
    {
        "Location": NotRequired[str],
        "CodeSha256": NotRequired[str],
        "CodeSize": NotRequired[int],
        "SigningProfileVersionArn": NotRequired[str],
        "SigningJobArn": NotRequired[str],
    },
)
GetPolicyRequestRequestTypeDef = TypedDict(
    "GetPolicyRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
    },
)
GetProvisionedConcurrencyConfigRequestRequestTypeDef = TypedDict(
    "GetProvisionedConcurrencyConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": str,
    },
)
GetRuntimeManagementConfigRequestRequestTypeDef = TypedDict(
    "GetRuntimeManagementConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
    },
)
ImageConfigErrorTypeDef = TypedDict(
    "ImageConfigErrorTypeDef",
    {
        "ErrorCode": NotRequired[str],
        "Message": NotRequired[str],
    },
)
ImageConfigOutputTypeDef = TypedDict(
    "ImageConfigOutputTypeDef",
    {
        "EntryPoint": NotRequired[List[str]],
        "Command": NotRequired[List[str]],
        "WorkingDirectory": NotRequired[str],
    },
)
InvokeResponseStreamUpdateTypeDef = TypedDict(
    "InvokeResponseStreamUpdateTypeDef",
    {
        "Payload": NotRequired[bytes],
    },
)
InvokeWithResponseStreamCompleteEventTypeDef = TypedDict(
    "InvokeWithResponseStreamCompleteEventTypeDef",
    {
        "ErrorCode": NotRequired[str],
        "ErrorDetails": NotRequired[str],
        "LogResult": NotRequired[str],
    },
)
LayerVersionsListItemTypeDef = TypedDict(
    "LayerVersionsListItemTypeDef",
    {
        "LayerVersionArn": NotRequired[str],
        "Version": NotRequired[int],
        "Description": NotRequired[str],
        "CreatedDate": NotRequired[str],
        "CompatibleRuntimes": NotRequired[List[RuntimeType]],
        "LicenseInfo": NotRequired[str],
        "CompatibleArchitectures": NotRequired[List[ArchitectureType]],
    },
)
PaginatorConfigTypeDef = TypedDict(
    "PaginatorConfigTypeDef",
    {
        "MaxItems": NotRequired[int],
        "PageSize": NotRequired[int],
        "StartingToken": NotRequired[str],
    },
)
ListAliasesRequestRequestTypeDef = TypedDict(
    "ListAliasesRequestRequestTypeDef",
    {
        "FunctionName": str,
        "FunctionVersion": NotRequired[str],
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
    },
)
ListCodeSigningConfigsRequestRequestTypeDef = TypedDict(
    "ListCodeSigningConfigsRequestRequestTypeDef",
    {
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
    },
)
ListEventSourceMappingsRequestRequestTypeDef = TypedDict(
    "ListEventSourceMappingsRequestRequestTypeDef",
    {
        "EventSourceArn": NotRequired[str],
        "FunctionName": NotRequired[str],
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
    },
)
ListFunctionEventInvokeConfigsRequestRequestTypeDef = TypedDict(
    "ListFunctionEventInvokeConfigsRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
    },
)
ListFunctionUrlConfigsRequestRequestTypeDef = TypedDict(
    "ListFunctionUrlConfigsRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
    },
)
ListFunctionsByCodeSigningConfigRequestRequestTypeDef = TypedDict(
    "ListFunctionsByCodeSigningConfigRequestRequestTypeDef",
    {
        "CodeSigningConfigArn": str,
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
    },
)
ListFunctionsRequestRequestTypeDef = TypedDict(
    "ListFunctionsRequestRequestTypeDef",
    {
        "MasterRegion": NotRequired[str],
        "FunctionVersion": NotRequired[Literal["ALL"]],
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
    },
)
ListLayerVersionsRequestRequestTypeDef = TypedDict(
    "ListLayerVersionsRequestRequestTypeDef",
    {
        "LayerName": str,
        "CompatibleRuntime": NotRequired[RuntimeType],
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
        "CompatibleArchitecture": NotRequired[ArchitectureType],
    },
)
ListLayersRequestRequestTypeDef = TypedDict(
    "ListLayersRequestRequestTypeDef",
    {
        "CompatibleRuntime": NotRequired[RuntimeType],
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
        "CompatibleArchitecture": NotRequired[ArchitectureType],
    },
)
ListProvisionedConcurrencyConfigsRequestRequestTypeDef = TypedDict(
    "ListProvisionedConcurrencyConfigsRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
    },
)
ProvisionedConcurrencyConfigListItemTypeDef = TypedDict(
    "ProvisionedConcurrencyConfigListItemTypeDef",
    {
        "FunctionArn": NotRequired[str],
        "RequestedProvisionedConcurrentExecutions": NotRequired[int],
        "AvailableProvisionedConcurrentExecutions": NotRequired[int],
        "AllocatedProvisionedConcurrentExecutions": NotRequired[int],
        "Status": NotRequired[ProvisionedConcurrencyStatusEnumType],
        "StatusReason": NotRequired[str],
        "LastModified": NotRequired[str],
    },
)
ListTagsRequestRequestTypeDef = TypedDict(
    "ListTagsRequestRequestTypeDef",
    {
        "Resource": str,
    },
)
ListVersionsByFunctionRequestRequestTypeDef = TypedDict(
    "ListVersionsByFunctionRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Marker": NotRequired[str],
        "MaxItems": NotRequired[int],
    },
)
PublishVersionRequestRequestTypeDef = TypedDict(
    "PublishVersionRequestRequestTypeDef",
    {
        "FunctionName": str,
        "CodeSha256": NotRequired[str],
        "Description": NotRequired[str],
        "RevisionId": NotRequired[str],
    },
)
PutFunctionCodeSigningConfigRequestRequestTypeDef = TypedDict(
    "PutFunctionCodeSigningConfigRequestRequestTypeDef",
    {
        "CodeSigningConfigArn": str,
        "FunctionName": str,
    },
)
PutFunctionConcurrencyRequestRequestTypeDef = TypedDict(
    "PutFunctionConcurrencyRequestRequestTypeDef",
    {
        "FunctionName": str,
        "ReservedConcurrentExecutions": int,
    },
)
PutFunctionRecursionConfigRequestRequestTypeDef = TypedDict(
    "PutFunctionRecursionConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "RecursiveLoop": RecursiveLoopType,
    },
)
PutProvisionedConcurrencyConfigRequestRequestTypeDef = TypedDict(
    "PutProvisionedConcurrencyConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": str,
        "ProvisionedConcurrentExecutions": int,
    },
)
PutRuntimeManagementConfigRequestRequestTypeDef = TypedDict(
    "PutRuntimeManagementConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "UpdateRuntimeOn": UpdateRuntimeOnType,
        "Qualifier": NotRequired[str],
        "RuntimeVersionArn": NotRequired[str],
    },
)
RemoveLayerVersionPermissionRequestRequestTypeDef = TypedDict(
    "RemoveLayerVersionPermissionRequestRequestTypeDef",
    {
        "LayerName": str,
        "VersionNumber": int,
        "StatementId": str,
        "RevisionId": NotRequired[str],
    },
)
RemovePermissionRequestRequestTypeDef = TypedDict(
    "RemovePermissionRequestRequestTypeDef",
    {
        "FunctionName": str,
        "StatementId": str,
        "Qualifier": NotRequired[str],
        "RevisionId": NotRequired[str],
    },
)
RuntimeVersionErrorTypeDef = TypedDict(
    "RuntimeVersionErrorTypeDef",
    {
        "ErrorCode": NotRequired[str],
        "Message": NotRequired[str],
    },
)
TagResourceRequestRequestTypeDef = TypedDict(
    "TagResourceRequestRequestTypeDef",
    {
        "Resource": str,
        "Tags": Mapping[str, str],
    },
)
UntagResourceRequestRequestTypeDef = TypedDict(
    "UntagResourceRequestRequestTypeDef",
    {
        "Resource": str,
        "TagKeys": Sequence[str],
    },
)
AddLayerVersionPermissionResponseTypeDef = TypedDict(
    "AddLayerVersionPermissionResponseTypeDef",
    {
        "Statement": str,
        "RevisionId": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
AddPermissionResponseTypeDef = TypedDict(
    "AddPermissionResponseTypeDef",
    {
        "Statement": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ConcurrencyResponseTypeDef = TypedDict(
    "ConcurrencyResponseTypeDef",
    {
        "ReservedConcurrentExecutions": int,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
EmptyResponseMetadataTypeDef = TypedDict(
    "EmptyResponseMetadataTypeDef",
    {
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
GetAccountSettingsResponseTypeDef = TypedDict(
    "GetAccountSettingsResponseTypeDef",
    {
        "AccountLimit": AccountLimitTypeDef,
        "AccountUsage": AccountUsageTypeDef,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
GetFunctionCodeSigningConfigResponseTypeDef = TypedDict(
    "GetFunctionCodeSigningConfigResponseTypeDef",
    {
        "CodeSigningConfigArn": str,
        "FunctionName": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
GetFunctionConcurrencyResponseTypeDef = TypedDict(
    "GetFunctionConcurrencyResponseTypeDef",
    {
        "ReservedConcurrentExecutions": int,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
GetFunctionRecursionConfigResponseTypeDef = TypedDict(
    "GetFunctionRecursionConfigResponseTypeDef",
    {
        "RecursiveLoop": RecursiveLoopType,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
GetLayerVersionPolicyResponseTypeDef = TypedDict(
    "GetLayerVersionPolicyResponseTypeDef",
    {
        "Policy": str,
        "RevisionId": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
GetPolicyResponseTypeDef = TypedDict(
    "GetPolicyResponseTypeDef",
    {
        "Policy": str,
        "RevisionId": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
GetProvisionedConcurrencyConfigResponseTypeDef = TypedDict(
    "GetProvisionedConcurrencyConfigResponseTypeDef",
    {
        "RequestedProvisionedConcurrentExecutions": int,
        "AvailableProvisionedConcurrentExecutions": int,
        "AllocatedProvisionedConcurrentExecutions": int,
        "Status": ProvisionedConcurrencyStatusEnumType,
        "StatusReason": str,
        "LastModified": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
GetRuntimeManagementConfigResponseTypeDef = TypedDict(
    "GetRuntimeManagementConfigResponseTypeDef",
    {
        "UpdateRuntimeOn": UpdateRuntimeOnType,
        "RuntimeVersionArn": str,
        "FunctionArn": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
InvocationResponseTypeDef = TypedDict(
    "InvocationResponseTypeDef",
    {
        "StatusCode": int,
        "FunctionError": str,
        "LogResult": str,
        "Payload": StreamingBody,
        "ExecutedVersion": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
InvokeAsyncResponseTypeDef = TypedDict(
    "InvokeAsyncResponseTypeDef",
    {
        "Status": int,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ListFunctionsByCodeSigningConfigResponseTypeDef = TypedDict(
    "ListFunctionsByCodeSigningConfigResponseTypeDef",
    {
        "NextMarker": str,
        "FunctionArns": List[str],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ListTagsResponseTypeDef = TypedDict(
    "ListTagsResponseTypeDef",
    {
        "Tags": Dict[str, str],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
PutFunctionCodeSigningConfigResponseTypeDef = TypedDict(
    "PutFunctionCodeSigningConfigResponseTypeDef",
    {
        "CodeSigningConfigArn": str,
        "FunctionName": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
PutFunctionRecursionConfigResponseTypeDef = TypedDict(
    "PutFunctionRecursionConfigResponseTypeDef",
    {
        "RecursiveLoop": RecursiveLoopType,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
PutProvisionedConcurrencyConfigResponseTypeDef = TypedDict(
    "PutProvisionedConcurrencyConfigResponseTypeDef",
    {
        "RequestedProvisionedConcurrentExecutions": int,
        "AvailableProvisionedConcurrentExecutions": int,
        "AllocatedProvisionedConcurrentExecutions": int,
        "Status": ProvisionedConcurrencyStatusEnumType,
        "StatusReason": str,
        "LastModified": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
PutRuntimeManagementConfigResponseTypeDef = TypedDict(
    "PutRuntimeManagementConfigResponseTypeDef",
    {
        "UpdateRuntimeOn": UpdateRuntimeOnType,
        "FunctionArn": str,
        "RuntimeVersionArn": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
AliasConfigurationResponseTypeDef = TypedDict(
    "AliasConfigurationResponseTypeDef",
    {
        "AliasArn": str,
        "Name": str,
        "FunctionVersion": str,
        "Description": str,
        "RoutingConfig": AliasRoutingConfigurationOutputTypeDef,
        "RevisionId": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
AliasConfigurationTypeDef = TypedDict(
    "AliasConfigurationTypeDef",
    {
        "AliasArn": NotRequired[str],
        "Name": NotRequired[str],
        "FunctionVersion": NotRequired[str],
        "Description": NotRequired[str],
        "RoutingConfig": NotRequired[AliasRoutingConfigurationOutputTypeDef],
        "RevisionId": NotRequired[str],
    },
)
CreateAliasRequestRequestTypeDef = TypedDict(
    "CreateAliasRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Name": str,
        "FunctionVersion": str,
        "Description": NotRequired[str],
        "RoutingConfig": NotRequired[AliasRoutingConfigurationTypeDef],
    },
)
UpdateAliasRequestRequestTypeDef = TypedDict(
    "UpdateAliasRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Name": str,
        "FunctionVersion": NotRequired[str],
        "Description": NotRequired[str],
        "RoutingConfig": NotRequired[AliasRoutingConfigurationTypeDef],
        "RevisionId": NotRequired[str],
    },
)
FunctionCodeTypeDef = TypedDict(
    "FunctionCodeTypeDef",
    {
        "ZipFile": NotRequired[BlobTypeDef],
        "S3Bucket": NotRequired[str],
        "S3Key": NotRequired[str],
        "S3ObjectVersion": NotRequired[str],
        "ImageUri": NotRequired[str],
    },
)
InvocationRequestRequestTypeDef = TypedDict(
    "InvocationRequestRequestTypeDef",
    {
        "FunctionName": str,
        "InvocationType": NotRequired[InvocationTypeType],
        "LogType": NotRequired[LogTypeType],
        "ClientContext": NotRequired[str],
        "Payload": NotRequired[BlobTypeDef],
        "Qualifier": NotRequired[str],
    },
)
InvokeAsyncRequestRequestTypeDef = TypedDict(
    "InvokeAsyncRequestRequestTypeDef",
    {
        "FunctionName": str,
        "InvokeArgs": BlobTypeDef,
    },
)
InvokeWithResponseStreamRequestRequestTypeDef = TypedDict(
    "InvokeWithResponseStreamRequestRequestTypeDef",
    {
        "FunctionName": str,
        "InvocationType": NotRequired[ResponseStreamingInvocationTypeType],
        "LogType": NotRequired[LogTypeType],
        "ClientContext": NotRequired[str],
        "Qualifier": NotRequired[str],
        "Payload": NotRequired[BlobTypeDef],
    },
)
LayerVersionContentInputTypeDef = TypedDict(
    "LayerVersionContentInputTypeDef",
    {
        "S3Bucket": NotRequired[str],
        "S3Key": NotRequired[str],
        "S3ObjectVersion": NotRequired[str],
        "ZipFile": NotRequired[BlobTypeDef],
    },
)
UpdateFunctionCodeRequestRequestTypeDef = TypedDict(
    "UpdateFunctionCodeRequestRequestTypeDef",
    {
        "FunctionName": str,
        "ZipFile": NotRequired[BlobTypeDef],
        "S3Bucket": NotRequired[str],
        "S3Key": NotRequired[str],
        "S3ObjectVersion": NotRequired[str],
        "ImageUri": NotRequired[str],
        "Publish": NotRequired[bool],
        "DryRun": NotRequired[bool],
        "RevisionId": NotRequired[str],
        "Architectures": NotRequired[Sequence[ArchitectureType]],
    },
)
CodeSigningConfigTypeDef = TypedDict(
    "CodeSigningConfigTypeDef",
    {
        "CodeSigningConfigId": str,
        "CodeSigningConfigArn": str,
        "AllowedPublishers": AllowedPublishersOutputTypeDef,
        "CodeSigningPolicies": CodeSigningPoliciesTypeDef,
        "LastModified": str,
        "Description": NotRequired[str],
    },
)
CreateCodeSigningConfigRequestRequestTypeDef = TypedDict(
    "CreateCodeSigningConfigRequestRequestTypeDef",
    {
        "AllowedPublishers": AllowedPublishersTypeDef,
        "Description": NotRequired[str],
        "CodeSigningPolicies": NotRequired[CodeSigningPoliciesTypeDef],
        "Tags": NotRequired[Mapping[str, str]],
    },
)
UpdateCodeSigningConfigRequestRequestTypeDef = TypedDict(
    "UpdateCodeSigningConfigRequestRequestTypeDef",
    {
        "CodeSigningConfigArn": str,
        "Description": NotRequired[str],
        "AllowedPublishers": NotRequired[AllowedPublishersTypeDef],
        "CodeSigningPolicies": NotRequired[CodeSigningPoliciesTypeDef],
    },
)
CreateFunctionUrlConfigResponseTypeDef = TypedDict(
    "CreateFunctionUrlConfigResponseTypeDef",
    {
        "FunctionUrl": str,
        "FunctionArn": str,
        "AuthType": FunctionUrlAuthTypeType,
        "Cors": CorsOutputTypeDef,
        "CreationTime": str,
        "InvokeMode": InvokeModeType,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
FunctionUrlConfigTypeDef = TypedDict(
    "FunctionUrlConfigTypeDef",
    {
        "FunctionUrl": str,
        "FunctionArn": str,
        "CreationTime": str,
        "LastModifiedTime": str,
        "AuthType": FunctionUrlAuthTypeType,
        "Cors": NotRequired[CorsOutputTypeDef],
        "InvokeMode": NotRequired[InvokeModeType],
    },
)
GetFunctionUrlConfigResponseTypeDef = TypedDict(
    "GetFunctionUrlConfigResponseTypeDef",
    {
        "FunctionUrl": str,
        "FunctionArn": str,
        "AuthType": FunctionUrlAuthTypeType,
        "Cors": CorsOutputTypeDef,
        "CreationTime": str,
        "LastModifiedTime": str,
        "InvokeMode": InvokeModeType,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
UpdateFunctionUrlConfigResponseTypeDef = TypedDict(
    "UpdateFunctionUrlConfigResponseTypeDef",
    {
        "FunctionUrl": str,
        "FunctionArn": str,
        "AuthType": FunctionUrlAuthTypeType,
        "Cors": CorsOutputTypeDef,
        "CreationTime": str,
        "LastModifiedTime": str,
        "InvokeMode": InvokeModeType,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
CreateFunctionUrlConfigRequestRequestTypeDef = TypedDict(
    "CreateFunctionUrlConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "AuthType": FunctionUrlAuthTypeType,
        "Qualifier": NotRequired[str],
        "Cors": NotRequired[CorsTypeDef],
        "InvokeMode": NotRequired[InvokeModeType],
    },
)
UpdateFunctionUrlConfigRequestRequestTypeDef = TypedDict(
    "UpdateFunctionUrlConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
        "AuthType": NotRequired[FunctionUrlAuthTypeType],
        "Cors": NotRequired[CorsTypeDef],
        "InvokeMode": NotRequired[InvokeModeType],
    },
)
UpdateFunctionConfigurationRequestRequestTypeDef = TypedDict(
    "UpdateFunctionConfigurationRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Role": NotRequired[str],
        "Handler": NotRequired[str],
        "Description": NotRequired[str],
        "Timeout": NotRequired[int],
        "MemorySize": NotRequired[int],
        "VpcConfig": NotRequired[VpcConfigTypeDef],
        "Environment": NotRequired[EnvironmentTypeDef],
        "Runtime": NotRequired[RuntimeType],
        "DeadLetterConfig": NotRequired[DeadLetterConfigTypeDef],
        "KMSKeyArn": NotRequired[str],
        "TracingConfig": NotRequired[TracingConfigTypeDef],
        "RevisionId": NotRequired[str],
        "Layers": NotRequired[Sequence[str]],
        "FileSystemConfigs": NotRequired[Sequence[FileSystemConfigTypeDef]],
        "ImageConfig": NotRequired[ImageConfigTypeDef],
        "EphemeralStorage": NotRequired[EphemeralStorageTypeDef],
        "SnapStart": NotRequired[SnapStartTypeDef],
        "LoggingConfig": NotRequired[LoggingConfigTypeDef],
    },
)
DestinationConfigTypeDef = TypedDict(
    "DestinationConfigTypeDef",
    {
        "OnSuccess": NotRequired[OnSuccessTypeDef],
        "OnFailure": NotRequired[OnFailureTypeDef],
    },
)
EnvironmentResponseTypeDef = TypedDict(
    "EnvironmentResponseTypeDef",
    {
        "Variables": NotRequired[Dict[str, str]],
        "Error": NotRequired[EnvironmentErrorTypeDef],
    },
)
FilterCriteriaOutputTypeDef = TypedDict(
    "FilterCriteriaOutputTypeDef",
    {
        "Filters": NotRequired[List[FilterTypeDef]],
    },
)
FilterCriteriaTypeDef = TypedDict(
    "FilterCriteriaTypeDef",
    {
        "Filters": NotRequired[Sequence[FilterTypeDef]],
    },
)
GetFunctionConfigurationRequestFunctionActiveWaitTypeDef = TypedDict(
    "GetFunctionConfigurationRequestFunctionActiveWaitTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
        "WaiterConfig": NotRequired[WaiterConfigTypeDef],
    },
)
GetFunctionConfigurationRequestFunctionUpdatedWaitTypeDef = TypedDict(
    "GetFunctionConfigurationRequestFunctionUpdatedWaitTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
        "WaiterConfig": NotRequired[WaiterConfigTypeDef],
    },
)
GetFunctionConfigurationRequestPublishedVersionActiveWaitTypeDef = TypedDict(
    "GetFunctionConfigurationRequestPublishedVersionActiveWaitTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
        "WaiterConfig": NotRequired[WaiterConfigTypeDef],
    },
)
GetFunctionRequestFunctionActiveV2WaitTypeDef = TypedDict(
    "GetFunctionRequestFunctionActiveV2WaitTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
        "WaiterConfig": NotRequired[WaiterConfigTypeDef],
    },
)
GetFunctionRequestFunctionExistsWaitTypeDef = TypedDict(
    "GetFunctionRequestFunctionExistsWaitTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
        "WaiterConfig": NotRequired[WaiterConfigTypeDef],
    },
)
GetFunctionRequestFunctionUpdatedV2WaitTypeDef = TypedDict(
    "GetFunctionRequestFunctionUpdatedV2WaitTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
        "WaiterConfig": NotRequired[WaiterConfigTypeDef],
    },
)
GetLayerVersionResponseTypeDef = TypedDict(
    "GetLayerVersionResponseTypeDef",
    {
        "Content": LayerVersionContentOutputTypeDef,
        "LayerArn": str,
        "LayerVersionArn": str,
        "Description": str,
        "CreatedDate": str,
        "Version": int,
        "CompatibleRuntimes": List[RuntimeType],
        "LicenseInfo": str,
        "CompatibleArchitectures": List[ArchitectureType],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
PublishLayerVersionResponseTypeDef = TypedDict(
    "PublishLayerVersionResponseTypeDef",
    {
        "Content": LayerVersionContentOutputTypeDef,
        "LayerArn": str,
        "LayerVersionArn": str,
        "Description": str,
        "CreatedDate": str,
        "Version": int,
        "CompatibleRuntimes": List[RuntimeType],
        "LicenseInfo": str,
        "CompatibleArchitectures": List[ArchitectureType],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ImageConfigResponseTypeDef = TypedDict(
    "ImageConfigResponseTypeDef",
    {
        "ImageConfig": NotRequired[ImageConfigOutputTypeDef],
        "Error": NotRequired[ImageConfigErrorTypeDef],
    },
)
InvokeWithResponseStreamResponseEventTypeDef = TypedDict(
    "InvokeWithResponseStreamResponseEventTypeDef",
    {
        "PayloadChunk": NotRequired[InvokeResponseStreamUpdateTypeDef],
        "InvokeComplete": NotRequired[InvokeWithResponseStreamCompleteEventTypeDef],
    },
)
LayersListItemTypeDef = TypedDict(
    "LayersListItemTypeDef",
    {
        "LayerName": NotRequired[str],
        "LayerArn": NotRequired[str],
        "LatestMatchingVersion": NotRequired[LayerVersionsListItemTypeDef],
    },
)
ListLayerVersionsResponseTypeDef = TypedDict(
    "ListLayerVersionsResponseTypeDef",
    {
        "NextMarker": str,
        "LayerVersions": List[LayerVersionsListItemTypeDef],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ListAliasesRequestListAliasesPaginateTypeDef = TypedDict(
    "ListAliasesRequestListAliasesPaginateTypeDef",
    {
        "FunctionName": str,
        "FunctionVersion": NotRequired[str],
        "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
    },
)
ListCodeSigningConfigsRequestListCodeSigningConfigsPaginateTypeDef = TypedDict(
    "ListCodeSigningConfigsRequestListCodeSigningConfigsPaginateTypeDef",
    {
        "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
    },
)
ListEventSourceMappingsRequestListEventSourceMappingsPaginateTypeDef = TypedDict(
    "ListEventSourceMappingsRequestListEventSourceMappingsPaginateTypeDef",
    {
        "EventSourceArn": NotRequired[str],
        "FunctionName": NotRequired[str],
        "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
    },
)
ListFunctionEventInvokeConfigsRequestListFunctionEventInvokeConfigsPaginateTypeDef = TypedDict(
    "ListFunctionEventInvokeConfigsRequestListFunctionEventInvokeConfigsPaginateTypeDef",
    {
        "FunctionName": str,
        "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
    },
)
ListFunctionUrlConfigsRequestListFunctionUrlConfigsPaginateTypeDef = TypedDict(
    "ListFunctionUrlConfigsRequestListFunctionUrlConfigsPaginateTypeDef",
    {
        "FunctionName": str,
        "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
    },
)
ListFunctionsByCodeSigningConfigRequestListFunctionsByCodeSigningConfigPaginateTypeDef = TypedDict(
    "ListFunctionsByCodeSigningConfigRequestListFunctionsByCodeSigningConfigPaginateTypeDef",
    {
        "CodeSigningConfigArn": str,
        "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
    },
)
ListFunctionsRequestListFunctionsPaginateTypeDef = TypedDict(
    "ListFunctionsRequestListFunctionsPaginateTypeDef",
    {
        "MasterRegion": NotRequired[str],
        "FunctionVersion": NotRequired[Literal["ALL"]],
        "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
    },
)
ListLayerVersionsRequestListLayerVersionsPaginateTypeDef = TypedDict(
    "ListLayerVersionsRequestListLayerVersionsPaginateTypeDef",
    {
        "LayerName": str,
        "CompatibleRuntime": NotRequired[RuntimeType],
        "CompatibleArchitecture": NotRequired[ArchitectureType],
        "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
    },
)
ListLayersRequestListLayersPaginateTypeDef = TypedDict(
    "ListLayersRequestListLayersPaginateTypeDef",
    {
        "CompatibleRuntime": NotRequired[RuntimeType],
        "CompatibleArchitecture": NotRequired[ArchitectureType],
        "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
    },
)
ListProvisionedConcurrencyConfigsRequestListProvisionedConcurrencyConfigsPaginateTypeDef = (
    TypedDict(
        "ListProvisionedConcurrencyConfigsRequestListProvisionedConcurrencyConfigsPaginateTypeDef",
        {
            "FunctionName": str,
            "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
        },
    )
)
ListVersionsByFunctionRequestListVersionsByFunctionPaginateTypeDef = TypedDict(
    "ListVersionsByFunctionRequestListVersionsByFunctionPaginateTypeDef",
    {
        "FunctionName": str,
        "PaginationConfig": NotRequired[PaginatorConfigTypeDef],
    },
)
ListProvisionedConcurrencyConfigsResponseTypeDef = TypedDict(
    "ListProvisionedConcurrencyConfigsResponseTypeDef",
    {
        "ProvisionedConcurrencyConfigs": List[ProvisionedConcurrencyConfigListItemTypeDef],
        "NextMarker": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
RuntimeVersionConfigTypeDef = TypedDict(
    "RuntimeVersionConfigTypeDef",
    {
        "RuntimeVersionArn": NotRequired[str],
        "Error": NotRequired[RuntimeVersionErrorTypeDef],
    },
)
ListAliasesResponseTypeDef = TypedDict(
    "ListAliasesResponseTypeDef",
    {
        "NextMarker": str,
        "Aliases": List[AliasConfigurationTypeDef],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
CreateFunctionRequestRequestTypeDef = TypedDict(
    "CreateFunctionRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Role": str,
        "Code": FunctionCodeTypeDef,
        "Runtime": NotRequired[RuntimeType],
        "Handler": NotRequired[str],
        "Description": NotRequired[str],
        "Timeout": NotRequired[int],
        "MemorySize": NotRequired[int],
        "Publish": NotRequired[bool],
        "VpcConfig": NotRequired[VpcConfigTypeDef],
        "PackageType": NotRequired[PackageTypeType],
        "DeadLetterConfig": NotRequired[DeadLetterConfigTypeDef],
        "Environment": NotRequired[EnvironmentTypeDef],
        "KMSKeyArn": NotRequired[str],
        "TracingConfig": NotRequired[TracingConfigTypeDef],
        "Tags": NotRequired[Mapping[str, str]],
        "Layers": NotRequired[Sequence[str]],
        "FileSystemConfigs": NotRequired[Sequence[FileSystemConfigTypeDef]],
        "ImageConfig": NotRequired[ImageConfigTypeDef],
        "CodeSigningConfigArn": NotRequired[str],
        "Architectures": NotRequired[Sequence[ArchitectureType]],
        "EphemeralStorage": NotRequired[EphemeralStorageTypeDef],
        "SnapStart": NotRequired[SnapStartTypeDef],
        "LoggingConfig": NotRequired[LoggingConfigTypeDef],
    },
)
PublishLayerVersionRequestRequestTypeDef = TypedDict(
    "PublishLayerVersionRequestRequestTypeDef",
    {
        "LayerName": str,
        "Content": LayerVersionContentInputTypeDef,
        "Description": NotRequired[str],
        "CompatibleRuntimes": NotRequired[Sequence[RuntimeType]],
        "LicenseInfo": NotRequired[str],
        "CompatibleArchitectures": NotRequired[Sequence[ArchitectureType]],
    },
)
CreateCodeSigningConfigResponseTypeDef = TypedDict(
    "CreateCodeSigningConfigResponseTypeDef",
    {
        "CodeSigningConfig": CodeSigningConfigTypeDef,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
GetCodeSigningConfigResponseTypeDef = TypedDict(
    "GetCodeSigningConfigResponseTypeDef",
    {
        "CodeSigningConfig": CodeSigningConfigTypeDef,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ListCodeSigningConfigsResponseTypeDef = TypedDict(
    "ListCodeSigningConfigsResponseTypeDef",
    {
        "NextMarker": str,
        "CodeSigningConfigs": List[CodeSigningConfigTypeDef],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
UpdateCodeSigningConfigResponseTypeDef = TypedDict(
    "UpdateCodeSigningConfigResponseTypeDef",
    {
        "CodeSigningConfig": CodeSigningConfigTypeDef,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ListFunctionUrlConfigsResponseTypeDef = TypedDict(
    "ListFunctionUrlConfigsResponseTypeDef",
    {
        "FunctionUrlConfigs": List[FunctionUrlConfigTypeDef],
        "NextMarker": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
FunctionEventInvokeConfigResponseTypeDef = TypedDict(
    "FunctionEventInvokeConfigResponseTypeDef",
    {
        "LastModified": datetime,
        "FunctionArn": str,
        "MaximumRetryAttempts": int,
        "MaximumEventAgeInSeconds": int,
        "DestinationConfig": DestinationConfigTypeDef,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
FunctionEventInvokeConfigTypeDef = TypedDict(
    "FunctionEventInvokeConfigTypeDef",
    {
        "LastModified": NotRequired[datetime],
        "FunctionArn": NotRequired[str],
        "MaximumRetryAttempts": NotRequired[int],
        "MaximumEventAgeInSeconds": NotRequired[int],
        "DestinationConfig": NotRequired[DestinationConfigTypeDef],
    },
)
PutFunctionEventInvokeConfigRequestRequestTypeDef = TypedDict(
    "PutFunctionEventInvokeConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
        "MaximumRetryAttempts": NotRequired[int],
        "MaximumEventAgeInSeconds": NotRequired[int],
        "DestinationConfig": NotRequired[DestinationConfigTypeDef],
    },
)
UpdateFunctionEventInvokeConfigRequestRequestTypeDef = TypedDict(
    "UpdateFunctionEventInvokeConfigRequestRequestTypeDef",
    {
        "FunctionName": str,
        "Qualifier": NotRequired[str],
        "MaximumRetryAttempts": NotRequired[int],
        "MaximumEventAgeInSeconds": NotRequired[int],
        "DestinationConfig": NotRequired[DestinationConfigTypeDef],
    },
)
EventSourceMappingConfigurationResponseTypeDef = TypedDict(
    "EventSourceMappingConfigurationResponseTypeDef",
    {
        "UUID": str,
        "StartingPosition": EventSourcePositionType,
        "StartingPositionTimestamp": datetime,
        "BatchSize": int,
        "MaximumBatchingWindowInSeconds": int,
        "ParallelizationFactor": int,
        "EventSourceArn": str,
        "FilterCriteria": FilterCriteriaOutputTypeDef,
        "FunctionArn": str,
        "LastModified": datetime,
        "LastProcessingResult": str,
        "State": str,
        "StateTransitionReason": str,
        "DestinationConfig": DestinationConfigTypeDef,
        "Topics": List[str],
        "Queues": List[str],
        "SourceAccessConfigurations": List[SourceAccessConfigurationTypeDef],
        "SelfManagedEventSource": SelfManagedEventSourceOutputTypeDef,
        "MaximumRecordAgeInSeconds": int,
        "BisectBatchOnFunctionError": bool,
        "MaximumRetryAttempts": int,
        "TumblingWindowInSeconds": int,
        "FunctionResponseTypes": List[Literal["ReportBatchItemFailures"]],
        "AmazonManagedKafkaEventSourceConfig": AmazonManagedKafkaEventSourceConfigTypeDef,
        "SelfManagedKafkaEventSourceConfig": SelfManagedKafkaEventSourceConfigTypeDef,
        "ScalingConfig": ScalingConfigTypeDef,
        "DocumentDBEventSourceConfig": DocumentDBEventSourceConfigTypeDef,
        "KMSKeyArn": str,
        "FilterCriteriaError": FilterCriteriaErrorTypeDef,
        "EventSourceMappingArn": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
EventSourceMappingConfigurationTypeDef = TypedDict(
    "EventSourceMappingConfigurationTypeDef",
    {
        "UUID": NotRequired[str],
        "StartingPosition": NotRequired[EventSourcePositionType],
        "StartingPositionTimestamp": NotRequired[datetime],
        "BatchSize": NotRequired[int],
        "MaximumBatchingWindowInSeconds": NotRequired[int],
        "ParallelizationFactor": NotRequired[int],
        "EventSourceArn": NotRequired[str],
        "FilterCriteria": NotRequired[FilterCriteriaOutputTypeDef],
        "FunctionArn": NotRequired[str],
        "LastModified": NotRequired[datetime],
        "LastProcessingResult": NotRequired[str],
        "State": NotRequired[str],
        "StateTransitionReason": NotRequired[str],
        "DestinationConfig": NotRequired[DestinationConfigTypeDef],
        "Topics": NotRequired[List[str]],
        "Queues": NotRequired[List[str]],
        "SourceAccessConfigurations": NotRequired[List[SourceAccessConfigurationTypeDef]],
        "SelfManagedEventSource": NotRequired[SelfManagedEventSourceOutputTypeDef],
        "MaximumRecordAgeInSeconds": NotRequired[int],
        "BisectBatchOnFunctionError": NotRequired[bool],
        "MaximumRetryAttempts": NotRequired[int],
        "TumblingWindowInSeconds": NotRequired[int],
        "FunctionResponseTypes": NotRequired[List[Literal["ReportBatchItemFailures"]]],
        "AmazonManagedKafkaEventSourceConfig": NotRequired[
            AmazonManagedKafkaEventSourceConfigTypeDef
        ],
        "SelfManagedKafkaEventSourceConfig": NotRequired[SelfManagedKafkaEventSourceConfigTypeDef],
        "ScalingConfig": NotRequired[ScalingConfigTypeDef],
        "DocumentDBEventSourceConfig": NotRequired[DocumentDBEventSourceConfigTypeDef],
        "KMSKeyArn": NotRequired[str],
        "FilterCriteriaError": NotRequired[FilterCriteriaErrorTypeDef],
        "EventSourceMappingArn": NotRequired[str],
    },
)
CreateEventSourceMappingRequestRequestTypeDef = TypedDict(
    "CreateEventSourceMappingRequestRequestTypeDef",
    {
        "FunctionName": str,
        "EventSourceArn": NotRequired[str],
        "Enabled": NotRequired[bool],
        "BatchSize": NotRequired[int],
        "FilterCriteria": NotRequired[FilterCriteriaTypeDef],
        "MaximumBatchingWindowInSeconds": NotRequired[int],
        "ParallelizationFactor": NotRequired[int],
        "StartingPosition": NotRequired[EventSourcePositionType],
        "StartingPositionTimestamp": NotRequired[TimestampTypeDef],
        "DestinationConfig": NotRequired[DestinationConfigTypeDef],
        "MaximumRecordAgeInSeconds": NotRequired[int],
        "BisectBatchOnFunctionError": NotRequired[bool],
        "MaximumRetryAttempts": NotRequired[int],
        "Tags": NotRequired[Mapping[str, str]],
        "TumblingWindowInSeconds": NotRequired[int],
        "Topics": NotRequired[Sequence[str]],
        "Queues": NotRequired[Sequence[str]],
        "SourceAccessConfigurations": NotRequired[Sequence[SourceAccessConfigurationTypeDef]],
        "SelfManagedEventSource": NotRequired[SelfManagedEventSourceTypeDef],
        "FunctionResponseTypes": NotRequired[Sequence[Literal["ReportBatchItemFailures"]]],
        "AmazonManagedKafkaEventSourceConfig": NotRequired[
            AmazonManagedKafkaEventSourceConfigTypeDef
        ],
        "SelfManagedKafkaEventSourceConfig": NotRequired[SelfManagedKafkaEventSourceConfigTypeDef],
        "ScalingConfig": NotRequired[ScalingConfigTypeDef],
        "DocumentDBEventSourceConfig": NotRequired[DocumentDBEventSourceConfigTypeDef],
        "KMSKeyArn": NotRequired[str],
    },
)
UpdateEventSourceMappingRequestRequestTypeDef = TypedDict(
    "UpdateEventSourceMappingRequestRequestTypeDef",
    {
        "UUID": str,
        "FunctionName": NotRequired[str],
        "Enabled": NotRequired[bool],
        "BatchSize": NotRequired[int],
        "FilterCriteria": NotRequired[FilterCriteriaTypeDef],
        "MaximumBatchingWindowInSeconds": NotRequired[int],
        "DestinationConfig": NotRequired[DestinationConfigTypeDef],
        "MaximumRecordAgeInSeconds": NotRequired[int],
        "BisectBatchOnFunctionError": NotRequired[bool],
        "MaximumRetryAttempts": NotRequired[int],
        "ParallelizationFactor": NotRequired[int],
        "SourceAccessConfigurations": NotRequired[Sequence[SourceAccessConfigurationTypeDef]],
        "TumblingWindowInSeconds": NotRequired[int],
        "FunctionResponseTypes": NotRequired[Sequence[Literal["ReportBatchItemFailures"]]],
        "ScalingConfig": NotRequired[ScalingConfigTypeDef],
        "DocumentDBEventSourceConfig": NotRequired[DocumentDBEventSourceConfigTypeDef],
        "KMSKeyArn": NotRequired[str],
    },
)
InvokeWithResponseStreamResponseTypeDef = TypedDict(
    "InvokeWithResponseStreamResponseTypeDef",
    {
        "StatusCode": int,
        "ExecutedVersion": str,
        "EventStream": "EventStream[InvokeWithResponseStreamResponseEventTypeDef]",
        "ResponseStreamContentType": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ListLayersResponseTypeDef = TypedDict(
    "ListLayersResponseTypeDef",
    {
        "NextMarker": str,
        "Layers": List[LayersListItemTypeDef],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
FunctionConfigurationResponseTypeDef = TypedDict(
    "FunctionConfigurationResponseTypeDef",
    {
        "FunctionName": str,
        "FunctionArn": str,
        "Runtime": RuntimeType,
        "Role": str,
        "Handler": str,
        "CodeSize": int,
        "Description": str,
        "Timeout": int,
        "MemorySize": int,
        "LastModified": str,
        "CodeSha256": str,
        "Version": str,
        "VpcConfig": VpcConfigResponseTypeDef,
        "DeadLetterConfig": DeadLetterConfigTypeDef,
        "Environment": EnvironmentResponseTypeDef,
        "KMSKeyArn": str,
        "TracingConfig": TracingConfigResponseTypeDef,
        "MasterArn": str,
        "RevisionId": str,
        "Layers": List[LayerTypeDef],
        "State": StateType,
        "StateReason": str,
        "StateReasonCode": StateReasonCodeType,
        "LastUpdateStatus": LastUpdateStatusType,
        "LastUpdateStatusReason": str,
        "LastUpdateStatusReasonCode": LastUpdateStatusReasonCodeType,
        "FileSystemConfigs": List[FileSystemConfigTypeDef],
        "PackageType": PackageTypeType,
        "ImageConfigResponse": ImageConfigResponseTypeDef,
        "SigningProfileVersionArn": str,
        "SigningJobArn": str,
        "Architectures": List[ArchitectureType],
        "EphemeralStorage": EphemeralStorageTypeDef,
        "SnapStart": SnapStartResponseTypeDef,
        "RuntimeVersionConfig": RuntimeVersionConfigTypeDef,
        "LoggingConfig": LoggingConfigTypeDef,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
FunctionConfigurationTypeDef = TypedDict(
    "FunctionConfigurationTypeDef",
    {
        "FunctionName": NotRequired[str],
        "FunctionArn": NotRequired[str],
        "Runtime": NotRequired[RuntimeType],
        "Role": NotRequired[str],
        "Handler": NotRequired[str],
        "CodeSize": NotRequired[int],
        "Description": NotRequired[str],
        "Timeout": NotRequired[int],
        "MemorySize": NotRequired[int],
        "LastModified": NotRequired[str],
        "CodeSha256": NotRequired[str],
        "Version": NotRequired[str],
        "VpcConfig": NotRequired[VpcConfigResponseTypeDef],
        "DeadLetterConfig": NotRequired[DeadLetterConfigTypeDef],
        "Environment": NotRequired[EnvironmentResponseTypeDef],
        "KMSKeyArn": NotRequired[str],
        "TracingConfig": NotRequired[TracingConfigResponseTypeDef],
        "MasterArn": NotRequired[str],
        "RevisionId": NotRequired[str],
        "Layers": NotRequired[List[LayerTypeDef]],
        "State": NotRequired[StateType],
        "StateReason": NotRequired[str],
        "StateReasonCode": NotRequired[StateReasonCodeType],
        "LastUpdateStatus": NotRequired[LastUpdateStatusType],
        "LastUpdateStatusReason": NotRequired[str],
        "LastUpdateStatusReasonCode": NotRequired[LastUpdateStatusReasonCodeType],
        "FileSystemConfigs": NotRequired[List[FileSystemConfigTypeDef]],
        "PackageType": NotRequired[PackageTypeType],
        "ImageConfigResponse": NotRequired[ImageConfigResponseTypeDef],
        "SigningProfileVersionArn": NotRequired[str],
        "SigningJobArn": NotRequired[str],
        "Architectures": NotRequired[List[ArchitectureType]],
        "EphemeralStorage": NotRequired[EphemeralStorageTypeDef],
        "SnapStart": NotRequired[SnapStartResponseTypeDef],
        "RuntimeVersionConfig": NotRequired[RuntimeVersionConfigTypeDef],
        "LoggingConfig": NotRequired[LoggingConfigTypeDef],
    },
)
ListFunctionEventInvokeConfigsResponseTypeDef = TypedDict(
    "ListFunctionEventInvokeConfigsResponseTypeDef",
    {
        "FunctionEventInvokeConfigs": List[FunctionEventInvokeConfigTypeDef],
        "NextMarker": str,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ListEventSourceMappingsResponseTypeDef = TypedDict(
    "ListEventSourceMappingsResponseTypeDef",
    {
        "NextMarker": str,
        "EventSourceMappings": List[EventSourceMappingConfigurationTypeDef],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
GetFunctionResponseTypeDef = TypedDict(
    "GetFunctionResponseTypeDef",
    {
        "Configuration": FunctionConfigurationTypeDef,
        "Code": FunctionCodeLocationTypeDef,
        "Tags": Dict[str, str],
        "Concurrency": ConcurrencyTypeDef,
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ListFunctionsResponseTypeDef = TypedDict(
    "ListFunctionsResponseTypeDef",
    {
        "NextMarker": str,
        "Functions": List[FunctionConfigurationTypeDef],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
ListVersionsByFunctionResponseTypeDef = TypedDict(
    "ListVersionsByFunctionResponseTypeDef",
    {
        "NextMarker": str,
        "Versions": List[FunctionConfigurationTypeDef],
        "ResponseMetadata": ResponseMetadataTypeDef,
    },
)
