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
# Date: 2018-06-01 01:46:22
# Author: Jacko Chang (jacko.chang@vivotek.com)
#

include role/libs/awscli/awscli.mk
include role/libs/awscli/exec.mk
include role/libs/awscli/ec2.mk

PHONY += launch

# $(eval $(call declare_vpc,$(SITENAME),10.0.0.0/16))
define declare_vpc
$(call vpc,$(1),$(2))
$(call tags,vpc_$(1),$$(call vpc_id,$(1)),Name:$(1))
launch: vpc tags_vpc_$(1)
endef

# $(eval $(call declare_subnet,a,$$(call vpc_id,$(SITENAME)),10.0.0.0/24,$(AWS_REGION)a,$(SITENAME)-subnet-$(1)))
define declare_subnet
$(call subnet,$(1),$(value 2),$(3),--availability-zone $(4))
$(call tags,subnet_$(1),$$(call subnet_id,$(1)),Name:$(value 5))
launch: subnet tags_subnet_$(1)
endef

# $(eval $(call declare_site_subnet,a,10.0.0.0/24,$(AWS_REGION)a))
define declare_site_subnet
$(call declare_subnet,$(1),$$(call vpc_id,$(SITENAME)),$(2),$(3),$(SITENAME)-subnet-$(1))
endef

# $(eval $(call declare_internet_gateway,a,$$(call vpc_id,$(SITENAME)),$(SITENAME)))
define declare_internet_gateway
$(call internet_gateway,a)
$(call exec,attach_internet_gateway_$(1),ec2,attach-internet-gateway, --internet-gateway-id $$(call internet_gateway_id,$(1)) --vpc-id $(value 2))
$(call tags,attach_internet_gateway_$(1),$$(call internet_gateway_id,a),Name:$(value 3))
launch: internet_gateway exec_attach_internet_gateway_$(1) tags_attach_internet_gateway_$(1)
endef

# $(eval $(call declare_site_internet_gateway,a))
define declare_site_internet_gateway
$(call declare_internet_gateway,$(1),$$(call vpc_id,$(SITENAME)),$(SITENAME))
endef

# $(eval $(call declare_route_table,a,$$(call vpc_id,$(SITENAME)),$$(call subnet_id,a),$(SITENAME)-route-$(1)))
define declare_route_table
$(call describe,route_table_$(1),vpc-id:$(value 2) association.main:true)
$(call exec,associate_route_table_$(1),ec2,associate-route-table, --route-table-id $$(call route_table_id,$(1)) --subnet-id $(value 3))
$(call tags,route_table_$(1),$$(call route_table_id,$(1)),Name:$(value 4))
launch: describe_route_table_$(1) exec_associate_route_table_$(1) tags_route_table_$(1)
endef

# $(eval $(call declare_site_route_table,a,$$(call subnet_id,a)))
define declare_site_route_table
$(call declare_route_table,$(1),$$(call vpc_id,$(SITENAME)),$(2),$(SITENAME)-route-$(1))
endef

# $(eval $(call declare_site_security_group,any_to_tcp_5566,tcp:5566:0.0.0.0/0,any_to_tcp_5566))
define declare_security_group
$(call security_group,$(1),$(2),--vpc-id $(value 3))
$(call sgai,security_group_$(1),$$(call security_group_id,$(1)),$(value 4))
$(call tags,security_group_$(1),$$(call security_group_id,$(1)),Name:$(value 5))
launch: security_group sgai_security_group_$(1) tags_security_group_$(1)
endef

# $(eval $(call declare_site_security_group,vpc_to_all,all:0-65535:10.0.0.0/16))
define declare_site_security_group
$(call declare_security_group,$(1),$(SITENAME)-sg-$(1),$$(call vpc_id,$(SITENAME)),$(2),$(SITENAME)-sg-$(1))
endef

# $(eval $(call declare_key_pair,$(SITENAME)))
define declare_key_pair
$(call key_pair,$(1))
$(call key_pair,$(1)-private)
launch: key_pair
endef

# $(eval $(call declare_instance,watchdog,,vpc_to_all,GROUP:WEB,--key-name $(SITENAME)-private --instance-typ t2.micro))
define declare_instance
$(call instance,$(1),$(if $(2),--iam-instance-profile $(2)) --security-group-ids $(foreach i,$(3),$$(call security_group_id,$(i))) $(value 5))
$(call tags,instance_$(1),$$(call instance_id,$(1)),Name:$(SITENAME)-$(1) $(4))
instance_sg_list += $(3)
launch: instance tags_instance_$(1)
endef

AMI_UBUNTU ?= $(shell cat role/libs/awscli/ubuntu_image.json | grep '"$(AWS_REGION)","xenial","16.04 LTS","amd64","hvm:ebs-ssd"' | sed -e 's/.*">//' -e 's/<\/a>.*//')

role/libs/awscli/ubuntu_image.json:
	curl -s 'https://cloud-images.ubuntu.com/locator/ec2/releasesTable' > $@~
	@mv $@~ $@

find-image:
	@echo Lookup ubuntu image for $(AWS_REGION):
	@curl -s 'https://cloud-images.ubuntu.com/locator/ec2/releasesTable' | grep '"$(AWS_REGION)","xenial","16.04 LTS","amd64","hvm:ebs-ssd"' | sed -e 's/.*">//' -e 's/<\/a>.*//'

PHONY += initial
initial::
	$(file >> .sitedef,AWS_REGION = $(shell $(AWS) configure get region))
	$(file >> .sitedef,AWS_ACCOUNT = $(shell $(AWS) sts get-caller-identity --output text --query 'Account'))
