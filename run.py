# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2015, Lars Asplund lars.anders.asplund@gmail.com

from os.path import join, dirname
from vunit.verilog import VUnit

root = dirname(__file__)

ui = VUnit.from_argv()

src_path = join(dirname(__file__), "src")

lib = ui.add_library("lib")

#lib.add_source_files(join(root, "src\\*.v"))
lib.add_source_files(join(root, "src\\*.sv"))
#lib.add_source_files(join(root, "src\\filter.sv"))
lib.add_source_files(join(root, "src\\test\\*.sv"))
#lib.add_source_files(join(root, "src\\test\\tb_filter.sv"))


ui.main()