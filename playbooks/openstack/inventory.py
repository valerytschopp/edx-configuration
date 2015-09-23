#!/usr/bin/env python

import requests
import argparse
import collections
import sys

try:
    import json
except:
    import simplejson as json


class OpenStackEdxInventory(object):

    metadata_url = "http://169.254.169.254/openstack/latest/meta_data.json"
    groups = ["app_servers", "backend_servers"]

    def __init__(self):
        pass

    def get_groups(self):
        groups = collections.defaultdict(list)
        response = requests.get(url = self.metadata_url)
        data = response.json()
        meta = data.get('meta')

        # Load groups
        for group in self.groups:
            group_str = meta.get(group)
            if group_str:
                groups[group] = json.loads(group_str)

        return groups

    def json_format_dict(self, data):
        return json.dumps(data, sort_keys=True, indent=2)

    def list_groups(self):
        groups = self.get_groups()
        print(self.json_format_dict(groups))

    def get_host(self, hostname):
        hostvars = collections.defaultdict(list)
        print(self.json_format_dict(hostvars))


def parse_args():
    parser = argparse.ArgumentParser(description='OpenStack Edx Inventory Module')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--list', action='store_true', help='List instances')
    group.add_argument('--host', help='List instance details')
    return parser.parse_args()


def main():
    args = parse_args()
    inventory = OpenStackEdxInventory()
    if args.list:
        inventory.list_groups()
    elif args.host:
        inventory.get_host(args.host)
    sys.exit(0)


if __name__ == '__main__':
    main()
