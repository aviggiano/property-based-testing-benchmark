import boto3
from os import environ
from shlex import quote

def put_object(key, value, local=False):
    if local:
        return open('/tmp/{}'.format(quote(key)), 'w').write(value)
    else:
        BUCKET = environ['S3_BUCKET']
        s3 = boto3.client('s3')
        response = s3.put_object(Bucket=BUCKET, Key=key, Body=value)
        return response['Body'].read()