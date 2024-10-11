"""
Type annotations for kinesis service client waiters.

[Open documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_kinesis/waiters/)

Usage::

    ```python
    from boto3.session import Session

    from mypy_boto3_kinesis.client import KinesisClient
    from mypy_boto3_kinesis.waiter import (
        StreamExistsWaiter,
        StreamNotExistsWaiter,
    )

    session = Session()
    client: KinesisClient = session.client("kinesis")

    stream_exists_waiter: StreamExistsWaiter = client.get_waiter("stream_exists")
    stream_not_exists_waiter: StreamNotExistsWaiter = client.get_waiter("stream_not_exists")
    ```
"""

import sys

from botocore.waiter import Waiter

from .type_defs import (
    DescribeStreamInputStreamExistsWaitTypeDef,
    DescribeStreamInputStreamNotExistsWaitTypeDef,
)

if sys.version_info >= (3, 12):
    from typing import Unpack
else:
    from typing_extensions import Unpack

__all__ = ("StreamExistsWaiter", "StreamNotExistsWaiter")

class StreamExistsWaiter(Waiter):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Waiter.StreamExists)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_kinesis/waiters/#streamexistswaiter)
    """
    def wait(self, **kwargs: Unpack[DescribeStreamInputStreamExistsWaitTypeDef]) -> None:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Waiter.StreamExists.wait)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_kinesis/waiters/#streamexistswaiter)
        """

class StreamNotExistsWaiter(Waiter):
    """
    [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Waiter.StreamNotExists)
    [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_kinesis/waiters/#streamnotexistswaiter)
    """
    def wait(self, **kwargs: Unpack[DescribeStreamInputStreamNotExistsWaitTypeDef]) -> None:
        """
        [Show boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Waiter.StreamNotExists.wait)
        [Show boto3-stubs documentation](https://youtype.github.io/boto3_stubs_docs/mypy_boto3_kinesis/waiters/#streamnotexistswaiter)
        """
