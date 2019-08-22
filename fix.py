import re
import sys
import yaml


def load(path):
    stream = open(path, 'r')

    return yaml.safe_load(stream)


def transform(old):
    new = {
        'file': {
            'size': old['size'],
            'checksums': old['checksums'],
        },
        'locations': {
            's3': old['locations'],
        },
    }

    return new


def write_file(stream, data):
    stream.write('file:\n   size: ')
    stream.write(f'{data["size"]}')
    stream.write('\n\n')
    stream.write(f'   checksums:')
    stream.write('\n')

    for algorithm, checksum in data['checksums'].items():
        stream.write(f'      {algorithm}: {checksum}')
        stream.write('\n')

    stream.write('\n\n')

    return


def write_locations(stream, locations):
    stream.write('locations:\n\n   s3:\n')

    for location in locations['s3']:
        stream.write(f'      -\n         bucket: {location["bucket"]}\n         key: {location["key"]}\n')

    return


def save(path, data):
    stream = open(path, 'w')

    stream.write('---\n\n\n')

    write_file(stream, data['file'])

    write_locations(stream, data['locations'])

    return


def compare(a, b):
    value = True

    try:
        for k, v_a in a.items():
            v_b = b[k]

            type_v_a = type(v_a)
            type_v_b = type(v_b)
            if type_v_a is type_v_b:
                if type_v_a is dict:
                    value = compare(
                        v_a,
                        v_b,
                    )
                else:
                    value = v_a == v_b
            else:
                value = False
                print(f'type of {k} differs: {type_v_a} vs {type_v_b}')
    except KeyError:
        value = False

    return value


def main(path):
    output_path = re.sub(
        r's3\.yaml$',
        'origin.yaml',
        path,
    )

    old_data = load(path)

    new_data = transform(old_data)

    save(
        output_path,
        new_data,
    )

    written_data = load(output_path)

    equal = compare(
        new_data,
        written_data,
    )

    exit_code = int(not equal)

    return exit_code


def cli_entry_point():
    exit_code = main(sys.argv[1])

    sys.exit(exit_code)

    return


if __name__ == '__main__':
    cli_entry_point()
