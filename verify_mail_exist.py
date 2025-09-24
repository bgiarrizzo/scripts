import re
import sys
import smtplib
from types import SimpleNamespace
from typing import Any
from socket import gethostbyname
from DNS import mxlookup
from validate_email import validate_email, VALID_ADDRESS_REGEXP


class EmailInfos(SimpleNamespace):
    email_address: str
    domain: str
    mx_servers: list[dict[str, dict[Any, Any]]]
    exists: bool


email_infos = EmailInfos()
email_infos.email_address = sys.argv[1]

if not re.match(VALID_ADDRESS_REGEXP, email_infos.email_address):
    raise ValueError("Mail address is not valid !")

email_infos.domain = email_infos.email_address.split("@")[1]
email_infos.mx_servers = []

for mx_host in mxlookup(email_infos.domain):
    smtp = smtplib.SMTP()
    try:
        result = {
            mx_host[1]: {
                "ip address": gethostbyname(mx_host[1]),
                "active": smtp.connect(mx_host[1]),
            }
        }
    except smtplib.SMTPConnectError:
        continue

    email_infos.mx_servers.append(result)


email_infos.exists = validate_email(
    email=email_infos.email_address,
    check_mx=False,
    verify=False,
)

print(email_infos)
