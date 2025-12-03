#! /usr/bin/env python3

"""
This script browse ip, starting from 0.0.0.0 to 255.255.255.255
For each IP it will get the service behind each open ports.
"""

import sys
import socket

import ipaddress

ip = sys.argv[1]

try:
    ip = ipaddress.ip_address(ip)
except ValueError:
    print("Invalid IP address")
    exit(1)

if ip.is_private:
    print("Private IP address detected. Scanning private IPs is not allowed.")
    exit(1)

print(f"Scanning {ip}")
# if ip is down then exit
try:
    socket.gethostbyaddr(str(ip))
    print(f"{ip} is up")
except socket.herror:
    print(f"{ip} is down")
    exit(1)

print("Scanning open ports...")
for port in range(1, 65536):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(0.5)
            result = s.connect_ex((str(ip), port))
            if result == 0:
                print(f"Port {port} is open on {ip}")
                try:
                    service = socket.getservbyport(port)
                    # Get service name and version using banner grabbing
                except OSError:
                    service = "Unknown"
                print(f"Port {port} is open on {ip}: {service}")
            # else:
            #     print(f"Port {port} closed on {ip}")
            #     continue
    except Exception as e:
        continue
