import argparse
import boto3
import hashlib
import os
import sys
import yaml


s3 = boto3.client('s3')

def process(bucket, prefix, filename):
    try:
        fd = os.open(
            path = filename,
            flags = os.O_RDONLY,
        )
        
        key = prefix + filename
        
        data = {
            'bucket': bucket,
            'checksums': {},
            'key': key,
            'size': os.fstat(fd).st_size,
        }
        
        hashobj = hashlib.sha512()
        
        f = os.fdopen(fd, 'rb')
        
        for chunk in iter(lambda: f.read(4096), b''):
            hashobj.update(chunk)
        
        data['checksums']['sha512'] = hashobj.hexdigest()
        
        s3.put_object(
            Body = f,
            Bucket = bucket,
            Key = key,
            Metadata = hashed,
        )
        
        with open(filename + '.efs.yaml', 'w') as output:
            yaml.dump(
                data,
                output,
                explicit_start = True,
                default_flow_style = False,
                indent = 3,
            )
        
        return True
    except:
        return False


parser = argparse.ArgumentParser()

parser.add_argument(
    '--bucket',
)

parser.add_argument(
    '--prefix',
)

parser.add_argument(
    'files',
    nargs = '+',
)

args = parser.parse_args()

if args.prefix:
    if not args.prefix.endswith('/'):
        prefix = args.prefix + '/'
    else:
        prefix = args.prefix
else:
    prefix = ''

exit_code = 0

for filename in args.files:
    exit_code += int(
        not
        process(
            bucket = args.bucket,
            prefix = prefix,
            filename = filename,
        )
    )

sys.exit(exit_code)
