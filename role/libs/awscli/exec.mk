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
# Date: 2018-06-04 01:57:17
# Author: Jacko Chang (jacko.chang@vivotek.com)
#

## exec
# $(eval $(call exec,attach_gateway,ec2,attach-internet-gateway, --internet-gateway-id $$(call internet_gateway_id,a) --vpc-id $$(call vpc_id,mycloud)))
# $(eval $(call exec,associate_route,ec2,associate-route-table, --route-table-id $$(call route_table_id,a) --subnet-id $$(call subnet_id,a)))

define exec
exec_$(1): .exec_$(1)
exec_$(1)_service = $(2)
exec_$(1)_command = $(3)
exec_$(1)_options = $(value 4)
endef

CLEAN += .exec_*

.exec_%:
	$(AWS) $(exec_$*_service) $(exec_$*_command) $(exec_$*_options)
	@touch $@

define exe2
exe2_$(1): .exec_$(1)
exe2_$(1)_service = $(2)
exe2_$(1)_command = $(3)
exe2_$(1)_options = $(value 4)
exe2_$(1)_convert = $(5)
exe2_$(1)_params = $(6)
endef

CLEAN += .exe2_*

.exe2_%:
	$(foreach i,$(exe2_$*_params),$(AWS) $(exe2_$*_service) $(exe2_$*_command) $(exe2_$*_options) $(call $(exe2_$*_convert),$(i))$(/n))
	@touch $@

