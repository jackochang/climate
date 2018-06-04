#
# Copyright (c) 2018 VIVOTEK Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Date: 2018-06-01 00:18:51
# Author: Jacko Chang (jacko.chang@vivotek.com)
#

SHELL = /bin/bash

TOPDIR := $(CURDIR)
export TOPDIR

include role/rules.mk

-include .config .sitedef

define USAGE
Quick reference for various supported make commands.
----------------------------------------------------
make %_default               restore site config
make distclean
make list                    display site list
make print-%                 display value
----------------------------------------------------
endef

PHONY += help
help: raw-output-USAGE

PHONY += clean
clean::
	$(if $(CLEAN),rm -rf $(CLEAN))

PHONY += distclean
distclean:: clean
	rm -f .config .sitedef make.site

list:
	@PS3='Choice:'; echo "Site list:"; select opt in $(shell ls -1 --ignore=common sites/); do \
		[ -z $$opt ] && continue; \
		$(MAKE) $${opt}_default; break; \
	done

%_default:
	( \
		echo SITENAME=$*; \
		echo SITEDIR=sites/$*; \
	) > .sitedef
	if [ -f sites/$*/config.default ]; then \
		cp sites/$*/config.default .config; \
	fi
	ln -s sites/$*/Makefile make.site
	$(MAKE) initial

-include make.site 

.PHONY: $(PHONY)

