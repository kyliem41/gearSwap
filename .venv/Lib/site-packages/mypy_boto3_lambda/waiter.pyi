"""
Type annotations for lambda service client waiters.

[Open documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/)

Usage::

    ```python
    from boto3.session import Session

    from mypy_boto3_lambda.client import LambdaClient
    from mypy_boto3_lambda.waiter import (
        FunctionActiveWaiter,
        FunctionActiveV2Waiter,
        FunctionExistsWaiter,
        FunctionUpdatedWaiter,
        FunctionUpdatedV2Waiter,
        PublishedVersionActiveWaiter,
    )

    session = Session()
    client: LambdaClient = session.client("lambda")

    function_active_waiter: FunctionActiveWaiter = client.get_waiter("function_active")
    function_active_v2_waiter: FunctionActiveV2Waiter = client.get_waiter("function_active_v2")
    function_exists_waiter: FunctionExistsWaiter = client.get_waiter("function_exists")
    function_updated_waiter: FunctionUpdatedWaiter = client.get_waiter("function_updated")
    function_updated_v2_waiter: FunctionUpdatedV2Waiter = client.get_waiter("function_updated_v2")
    published_version_active_waiter: PublishedVersionActiveWaiter = client.get_waiter("published_version_active")
    ```
"""

import sys

from botocore.waiter import Waiter

from .type_defs import (
    GetFunctionConfigurationRequestFunctionActiveWaitTypeDef,
    GetFunctionConfigurationRequestFunctionUpdatedWaitTypeDef,
    GetFunctionConfigurationRequestPublishedVersionActiveWaitTypeDef,
    GetFunctionRequestFunctionActiveV2WaitTypeDef,
    GetFunctionRequestFunctionExistsWaitTypeDef,
    GetFunctionRequestFunctionUpdatedV2WaitTypeDef,
)

if sys.version_info >= (3, 12):
    from typing import Unpack
else:
    from typing_extensions import Unpack

__all__ = (
    "FunctionActiveWaiter",
    "FunctionActiveV2Waiter",
    "FunctionExistsWaiter",
    "FunctionUpdatedWaiter",
    "FunctionUpdatedV2Waiter",
    "PublishedVersionActiveWaiter",
)

class FunctionActiveWaiter(Waiter):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.FunctionActive)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#functionactivewaiter)
    """
    def wait(
        self, **kwargs: Unpack[GetFunctionConfigurationRequestFunctionActiveWaitTypeDef]
    ) -> None:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.FunctionActive.wait)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#functionactivewaiter)
        """

class FunctionActiveV2Waiter(Waiter):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.FunctionActiveV2)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#functionactivev2waiter)
    """
    def wait(self, **kwargs: Unpack[GetFunctionRequestFunctionActiveV2WaitTypeDef]) -> None:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.FunctionActiveV2.wait)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#functionactivev2waiter)
        """

class FunctionExistsWaiter(Waiter):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.FunctionExists)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#functionexistswaiter)
    """
    def wait(self, **kwargs: Unpack[GetFunctionRequestFunctionExistsWaitTypeDef]) -> None:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.FunctionExists.wait)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#functionexistswaiter)
        """

class FunctionUpdatedWaiter(Waiter):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.FunctionUpdated)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#functionupdatedwaiter)
    """
    def wait(
        self, **kwargs: Unpack[GetFunctionConfigurationRequestFunctionUpdatedWaitTypeDef]
    ) -> None:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.FunctionUpdated.wait)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#functionupdatedwaiter)
        """

class FunctionUpdatedV2Waiter(Waiter):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.FunctionUpdatedV2)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#functionupdatedv2waiter)
    """
    def wait(self, **kwargs: Unpack[GetFunctionRequestFunctionUpdatedV2WaitTypeDef]) -> None:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.FunctionUpdatedV2.wait)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#functionupdatedv2waiter)
        """

class PublishedVersionActiveWaiter(Waiter):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.PublishedVersionActive)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#publishedversionactivewaiter)
    """
    def wait(
        self, **kwargs: Unpack[GetFunctionConfigurationRequestPublishedVersionActiveWaitTypeDef]
    ) -> None:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/lambda.html#Lambda.Waiter.PublishedVersionActive.wait)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_lambda/waiters/#publishedversionactivewaiter)
        """
