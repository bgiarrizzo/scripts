"""
This script will get an url from arg[1]
And add it to HWH git repo
"""

#! /usr/bin/env python3

import json
import requests
import sys

from bs4 import BeautifulSoup
from datetime import datetime
from html.parser import HTMLParser
from slugify import slugify
from urllib.parse import urlparse


def get_url_from_args():
    """
    From sys.argv, check if there is only one argument.
    Check if the argument is an url
    return url as string
    """

    args = sys.argv[1:]

    if not args:
        print("No Url Provided for link")
        sys.exit()

    if len(args) > 1:
        print("Too much args provided")
        sys.exit()

    arg = args[0]

    parsed_url = urlparse(arg)

    if not parsed_url.hostname and not parsed_url.scheme:
        print("no url provided")
        sys.exit()

    return arg


def get_html_page(url: str):
    response = requests.get(url)

    if response.status_code != 200:
        raise FileNotFoundError

    return response.text


def get_link_title(html_page: str):
    soup = BeautifulSoup(html_page, "html.parser")
    soup_title = soup.find("title")
    return soup_title.string


def get_link_comment():
    input_comment = input("Your Comment (one line only) : ")
    return input_comment


def get_link_tags():
    input_tags = input("Tags (separate with commas ',' or ', ') : ")
    tag_list = input_tags.split(",")
    return [tag.strip() for tag in tag_list]


def craft_link_filename(date: str, slug: str):
    return f"{date}-{slug}.md"


if __name__ == "__main__":
    link_data = {}

    link_data["url"] = get_url_from_args()
    print("Getting URL")
    html_page = get_html_page(link_data["url"])

    # Get Date
    link_data["date"] = {}
    link_data["date"]["now"] = datetime.now()
    link_data["date"]["short"] = link_data["date"]["now"].strftime("%Y-%m-%d")
    link_data["date"]["full"] = link_data["date"]["now"].strftime(
        "%Y-%m-%dT%H:%M:%S+01:00"
    )

    # Get Title
    print("Getting link title ...")
    link_data["title"] = get_link_title(html_page=html_page)

    # Slugify Title
    link_data["slug"] = slugify(link_data["title"])

    # Prepare Filename
    link_data["filename"] = craft_link_filename(
        date=link_data["date"]["short"],
        slug=link_data["slug"],
    )

    # Get Comment
    link_data["comment"] = get_link_comment()

    # Get Tags
    link_data["tags"] = get_link_tags()

    link_data["date"].pop("now")

    print(
        json.dumps(link_data, indent=4, sort_keys=True, ensure_ascii=False),
    )
