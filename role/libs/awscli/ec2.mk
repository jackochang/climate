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
# Date: 2018-06-01 01:58:41
# Author: Jacko Chang (jacko.chang@vivotek.com)
#

## vpc
# $(eval $(call vpc,mycloud,10.0.0.0/16))

PHONY += vpc
define vpc
vpc: vpc_$(1).json
vpc_$(1)_cdir = $(2)
vpc_$(1)_opts = $(value 3)
endef

CLEAN += vpc_*.json{,~}

vpc_%.json:
	$(AWS) ec2 create-vpc --cidr-block $(vpc_$*_cdir) $(vpc_$*_opts) > $@~
	@jq '.Vpc' $@~ > $@
	@rm $@~

vpc_id = $(shell jq --raw-output '.VpcId' vpc_$(1).json)

## subnet
# $(eval $(call subnet,a,$$(call vpc_id,mycloud),10.0.0.0/24,--availability-zone $(AWS_REGION)a))
# $(eval $(call subnet,b,$$(call vpc_id,mycloud),10.0.1.0/24,--availability-zone $(AWS_REGION)b))

PHONY += subnet
define subnet
subnet: subnet_$(1).json
subnet_$(1)_vpc = $(value 2)
subnet_$(1)_cdir = $(3)
subnet_$(1)_opts = $(value 4)
endef

CLEAN += subnet_*.json{,~}

subnet_%.json:
	$(AWS) ec2 create-subnet --vpc-id $(subnet_$*_vpc) --cidr-block $(subnet_$*_cdir) $(subnet_$*_opts) > $@~
	@jq '.Subnet' $@~ > $@
	@rm $@~

subnet_id = $(shell jq --raw-output '.SubnetId' subnet_$(1).json)

## internet_gateway
# $(eval $(call internet_gateway,default))

PHONY += internet_gateway
define internet_gateway
internet_gateway: internet_gateway_$(1).json
internet_gateway_$(1)_opts = $(value 2)
endef

CLEAN += internet_gateway_*.json{,~}

internet_gateway_%.json:
	$(AWS) ec2 create-internet-gateway $(internet_gateway_$*_opts) > $@~
	@jq '.InternetGateway' $@~ > $@
	@rm $@~

internet_gateway_id = $(shell jq --raw-output '.InternetGatewayId' internet_gateway_$(1).json)

## security-group
# $(eval $(call security_group,vpc_to_all,$(SITENAME)))

define security_group
security_group: security_group_$(1).json
security_group_$(1)_desc = $(2)
security_group_$(1)_opts = $(value 3)
endef

CLEAN += security_group_*.json{,~}

security_group_%.json:
	$(AWS) ec2 create-security-group --group-name $* --description $(security_group_$*_desc) $(security_group_$*_opts) > $@~
	@mv $@~ $@

security_group_id = $(shell jq --raw-output '.GroupId' security_group_$(1).json)

## key_pair
# $(eval $(call key_pair,$(SITENAME)))
# $(eval $(call key_pair,$(SITENAME)-private))

PHONY += key_pair
define key_pair
key_pair: $(SITEDIR)/$(1).pem
endef

%.pem:
	$(AWS) ec2 create-key-pair --key-name $(notdir $*) --query 'KeyMaterial' --output text > $@~
	chmod 400 $@~
	@mv $@~ $@

## instance
# $(eval $(call instance,watchdog,--image-id $(AMI_UBUNTU)))

PHONY += instance
define instance
instance: instance_$(1).json
instance_$(1)_opts =  $(INSTANCE_DEFAULT_OPTIONS) $(value 2)
endef

CLEAN += instance_*.json{,~}

instance_%.json:
	$(AWS) ec2 run-instances $(instance_$*_opts) > $@~
	@jq '.Instances[0]' $@~ > $@
	@rm -f $@~

instance_id = $(shell jq --raw-output '.InstanceId' instance_$(1).json)

## describe
# $(eval $(call describe,route_table_a,vpc-id:$$(call vpc_id,mycloud) association.main:true))

define describe
describe_$(1): describe_$(1).json
describe_$(1)_filters = $(2)
describe_$(1)_opts = $(value 3)
endef

CLEAN += describe_*.json{,~}

describe_route_table_%.json:
	$(AWS) ec2 describe-route-tables --filters $(foreach i,$(describe_route_table_$*_filters), "$(call describe_rule,$(subst :, ,$(i)))") $(describe_route_table_$*_opts) > $@~
	@jq '.RouteTables[0]' $@~ > $@
	@rm $@~

$(eval $(call extend,describe_rule,Name=$$(1)$(,)Values=$$(2)))

route_table_id = $(shell jq --raw-output '.RouteTableId' describe_route_table_$(1).json)

## tags
# $(eval $(call tags,vpc,$$(call vpc_id,mycloud),Name:$(SITENAME)))
# $(eval $(call tags,subnet_a,$$(call subnet_id,a),Name:$(SITENAME)-subnet-a))

define tags
$(call exec,tags_$(1),ec2,create-tags,--resource $(value 2) --tags $(foreach i,$(value 3),"$(call tags_rule,$(subst :, ,$(i)))"))
tags_$(1): .exec_tags_$(1)
endef

$(eval $(call extend,tags_rule,Key=$$(1)$(,)Value=$$(2)))

## sgai
# $(call sgai,security_group_$(1),$$(call security_group_id,vpc_to_all),all:0-65535:10.0.0.0/16)

define sgai
$(call exe2,sgai_$(1),ec2,authorize-security-group-ingress,--group-id $(2),sgai_convert,$(3))
sgai_$(1): .exe2_sgai_$(1)
endef

define sgai_convert
$(call sgai_rule,$(subst :, ,$(1)))

endef

$(eval $(call extend,sgai_rule,--protocol $$(1) --port $$(2) $_(if $_(filter sg-%,$$(3)),--source-group,--cidr) $$(3)))
