#!/usr/bin/env python3
import io
import re
import requests
import sys
from zipfile import ZipFile

def main():
    debug = True
    # based on https://github.com/Vampire/setup-wsl/blob/master/src/main/kotlin/net/kautler/github/action/setup_wsl/Distribution.kt
    # and https://gist.github.com/kou1okada/67729443c83859c2789b5d9ef0782fe4
    productId = '9p804crf0395'

    params = {
        'type': 'ProductId',
        'url': productId,
    }
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}

    r = requests.post(
        url='https://store.rg-adguard.net/api/GetFiles',
        headers=headers,
        data=params,
    )

    r.raise_for_status()
    if debug:
        print(r.content)
    data=r.content.decode('utf-8')
    match = re.search(r'<a [^>]*href="([^"]+)"[^>]*>[^<]*\.appx(?:bundle)</a>', data)
    assert(match)
    #url = re.search(r'a ', data)
    url = match.group(1)
    if debug:
        print(url)
    r = requests.get(url)
    zip = ZipFile(io.BytesIO(r.content))
    if debug:
        zip.printdir()
    appx = zip.read('DistroLauncher-Appx_1.6.0.0_x64.appx')
    zip = ZipFile(io.BytesIO(appx))
    if debug:
        zip.printdir()
    fname='Alpine.exe'
    data = zip.read(fname)
    with open(fname, "wb") as exe:
        exe.write(data)
    print(f'{fname}:{len(data)} bytes')

if __name__ == '__main__':
    sys.exit(main())
