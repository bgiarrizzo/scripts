"""
This script will get an url from arg[1]
And add it to HWH git repo
"""

#! /usr/bin/env python3

import sys
from urllib import parse as urlparse


def get_url_from_args():
    """
    From sys.argv, check if there is only one argument.
    Check if the argument is an url
    return URL as string
    """

    args = sys.argv[1:]

    if not args:
        print("No Url Provided for link")
        sys.exit()

    if len(args) > 1:
        print("Too much args provided")
        sys.exit()

    arg = args[0]

    parsed_url = urlparse.urlparse(arg)

    if not parsed_url.hostname and not parsed_url.scheme:
        print("no url provided")
        sys.exit()

    return arg


if __name__ == "__main__":
    url = get_url_from_args()

    print(f"url = {url}")
