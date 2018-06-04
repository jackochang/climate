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
# Date: 2018-06-04 09:36:33
# Author: Jacko Chang (jacko.chang@vivotek.com)
#

include role/aws.mk

AWS_OPTIONS += --profile sandbox-beta

VPC_CDIR = 10.0.0.0/16
SUBNET_A_CDIR = 10.0.0.0/24
SUBNET_B_CDIR = 10.0.1.0/24

# vpc
$(eval $(call declare_vpc,$(SITENAME),$(VPC_CDIR)))

# subnet
$(eval $(call declare_site_subnet,a,$(SUBNET_A_CDIR),$(AWS_REGION)a))
$(eval $(call declare_site_subnet,b,$(SUBNET_B_CDIR),$(AWS_REGION)b))

# internet gateway
$(eval $(call declare_site_internet_gateway,a))

# route tables
$(eval $(call declare_site_route_table,a,$$(call subnet_id,a)))

# security group
$(eval $(call declare_site_security_group,any_to_tcp_80,tcp:80:0.0.0.0/0))
$(eval $(call declare_site_security_group,elb_to_tcp_80,tcp:80:$$(call security_group_id,any_to_tcp_80)))
$(eval $(call declare_site_security_group,vpc_to_all,all:0-65535:$(VPC_CDIR)))

# key pair
$(eval $(call declare_key_pair,$(SITENAME)))

# instance
INSTANCE_DEFAULT_OPTIONS = --image-id $(AMI_UBUNTU) \
	--key-name $(SITENAME) \
	--subnet-id $$(call subnet_id,a) \
	--instance-typ t2.micro \
	--associate-public-ip-address
$(eval $(call declare_instance,protal,,elb_to_tcp_80 vpc_to_all,GROUP:WEB))
