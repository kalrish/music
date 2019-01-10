import argparse
import boto3
import git
import hashlib
import os
import sys
import yaml


s3 = boto3.client('s3')

def checksum_sha512(fh):
    hashobj = hashlib.sha512()
    
    for chunk in iter(lambda: fh.read(4096), b''):
        hashobj.update(chunk)
    
    return hashobj.hexdigest()

def process_files(repo, bucket, prefix, paths):
    failed = 0
    
    for path in paths:
        fd = os.open(
            path = path,
            flags = os.O_RDONLY,
        )
        
        if fd:
            fh = os.fdopen(fd, 'rb')
            if fh:
                data = {}
                
                key = prefix + path
                
                data['bucket'] = bucket
                data['key'] = key
                data['size'] = os.fstat(fd).st_size
                
                sha512 = checksum_sha512(fh)
                
                data['checksums'] = {}
                data['checksums']['sha512'] = sha512
                
                metadata = {}
                metadata['sha512'] = sha512
                
                fh.seek(0)
                
                s3.put_object(
                    Body = fh,
                    Bucket = bucket,
                    Key = key,
                    Metadata = metadata,
                )
                
                efs_filename = path + '.efs.yaml'
                
                efs_file = open(efs_filename, 'w', newline='')
                if efs_file:
                    output = efs_file
                else:
                    output = sys.stdout
                
                yaml.dump(
                    data,
                    output,
                    explicit_start = True,
                    default_flow_style = False,
                    indent = 3,
                )
                
                if output == sys.stdout:
                    ++failed
                else:
                    repo.index.add([efs_filename])
            else:
                ++failed
    
    return failed


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

repo = git.Repo()

if args.prefix:
    if not args.prefix.endswith('/'):
        prefix = args.prefix + '/'
    else:
        prefix = args.prefix
else:
    prefix = ''

exit_code = process_files(
    repo,
    args.bucket,
    prefix,
    args.files,
)

sys.exit(exit_code)
