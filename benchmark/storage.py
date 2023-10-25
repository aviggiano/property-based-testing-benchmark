import boto3
import logging
from os import environ
from shlex import quote


def put_object(key: str, value: str, local=False):
    logging.info('Saving to {}: {}'.format(key, value))
    if local:
        return open(key, 'w').write(value)
    else:
        BUCKET = environ['S3_BUCKET']
        s3 = boto3.client('s3')
        s3.put_object(Bucket=BUCKET, Key=key, Body=value)
