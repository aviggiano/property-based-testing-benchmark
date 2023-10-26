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


def get_object(key: str, local=False):
    logging.info('Downloading {}'.format(key))
    if local:
        return open(key, 'r+').read(value)
    else:
        BUCKET = environ['S3_BUCKET']
        s3 = boto3.client('s3')
        response = s3.get_object(Bucket=BUCKET, Key=key)
        return response['Body'].read()


def list_objects(prefix='', local=False):
    logging.info('Listing objects with prefix {}'.format(prefix))
    if local:
        raise NotImplementedError()
    else:
        BUCKET = environ['S3_BUCKET']
        s3 = boto3.client('s3')
        response = s3.list_objects(Bucket=BUCKET, Prefix=prefix)
        return list(map(lambda x: x['Key'], response['Contents']))
