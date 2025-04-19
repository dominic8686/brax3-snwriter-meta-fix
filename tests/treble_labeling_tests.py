# Copyright 2025 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

'''
Verify that Treble labeling are enforced.

Treble labeling means the following:

1) All platform processes are marked as "coredomain".
2) All platform processes are labeled by platform SEPolicy.
3) All vendor processes are NOT marked as "coredomain".

Note that vendor processes can be "labeled" by platform SEPolicy, if the
processes are generic to all vendors, such as sh / toybox / etc.

'''

import argparse
import os
import pkgutil
import policy
import re
import shutil
import sys
import tempfile

SHARED_LIB_EXTENSION = '.dylib' if sys.platform == 'darwin' else '.so'


def build_argument_parser():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--platform_apks",
        dest="platform_apks",
        metavar="FILE",
        help="Path to a file containing a list of platform apk files (one per line)",
        required=True,
    )
    parser.add_argument(
        "--vendor_apks",
        dest="vendor_apks",
        metavar="FILE",
        help="Path to a file containing a list of vendor apk files (one per line)",
        required=True,
    )
    parser.add_argument(
        "--precompiled_sepolicy_without_vendor",
        dest="precompiled_sepolicy_without_vendor",
        metavar="FILE",
        help="Path to the precompiled SEPolicy file (excluding vendor)",
        required=True,
    )
    parser.add_argument(
        "--precompiled_sepolicy",
        dest="precompiled_sepolicy",
        metavar="FILE",
        help="Path to the precompiled SEPolicy file (including vendor)",
        required=True,
    )
    parser.add_argument(
        "--platform_seapp_contexts",
        dest="platform_seapp_contexts",
        metavar="FILE",
        nargs="+",
        help="Path to the Platform seapp_contexts file",
        required=True,
    )
    parser.add_argument(
        "--vendor_file_contexts",
        dest="vendor_file_contexts",
        metavar="FILE",
        nargs="+",
        help="Path to the Vendor file_contexts file",
        required=True,
    )
    parser.add_argument(
        "--vendor_seapp_contexts",
        dest="vendor_seapp_contexts",
        metavar="FILE",
        nargs="+",
        help="Path to the Vendor seapp_contexts file",
        required=True,
    )
    parser.add_argument(
        "--aapt2_path",
        dest="aapt2_path",
        metavar="FILE",
        help="Path to the aapt2 executable.",
        required=True,
    )
    return parser

def do_main(libpath):
    parser = build_argument_parser()
    print(repr(parser.parse_args()))

if __name__ == '__main__':
    with tempfile.TemporaryDirectory() as temp_dir:
        libname = "libsepolwrap" + SHARED_LIB_EXTENSION
        libpath = os.path.join(temp_dir, libname)
        with open(libpath, "wb") as f:
            blob = pkgutil.get_data("treble_labeling_tests", libname)
            if not blob:
                sys.exit("Error: libsepolwrap does not exist. Is this binary corrupted?\n")
            f.write(blob)
        do_main(libpath)
