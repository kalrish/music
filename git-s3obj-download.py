import argparse
import boto3
import sys
import yaml


def process_directory(path):
    return True


parser = argparse.ArgumentParser()

parser.add_argument(
    'directory',
)

args = parser.parse_args()

sys.exit(
    int(
        not
        process_directory(args.directory)
    )
)
