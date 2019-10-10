#
# Copyright (C) 2011-2017 Intel Corporation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#   * Neither the name of Intel Corporation nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#

Current_Makefile_Dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

Native_Extra_CFlags :=
Native_Extra_CFlags += -DAPP_PIPELINE_FIREWALL_MAX_RULES_IN_FILE=262144
Native_Extra_CFlags += -DMSG_TIMEOUT_DEFAULT=200000

ifneq ($(TRIE),)
Native_Extra_CFlags += -DTRIE_FOOTPRINT
endif

######## Feature Selection #######

Enclave_Feature_Flags :=
ifneq ($(ENABLE_FULL_COPY),)
Enclave_Feature_Flags += -DENABLE_FULL_COPY
else
Enclave_Feature_Flags += -DENABLE_HEADER_COPY
endif
ifneq ($(ENABLE_INPUT_SKETCH),)
Enclave_Feature_Flags += -DENABLE_INPUT_SKETCH
endif
ifneq ($(ENABLE_OUTPUT_COUNT),)
Enclave_Feature_Flags += -DENABLE_OUTPUT_COUNT
endif

######## DPDK SDK Settings ########

ifeq ($(RTE_SDK),)
$(error "Please define RTE_SDK environment variable")
endif

# Default target, can be overriden by command line or environment
RTE_TARGET ?= x86_64-native-linuxapp-gcc

DPDK_C_CPU_Flags := -m64 -march=native -DRTE_MACHINE_CPUFLAG_SSE \
	-DRTE_MACHINE_CPUFLAG_SSE2 -DRTE_MACHINE_CPUFLAG_SSE3 \
	-DRTE_MACHINE_CPUFLAG_SSSE3 -DRTE_MACHINE_CPUFLAG_SSE4_1 \
	-DRTE_MACHINE_CPUFLAG_SSE4_2 -DRTE_MACHINE_CPUFLAG_AES \
	-DRTE_MACHINE_CPUFLAG_PCLMULQDQ -DRTE_MACHINE_CPUFLAG_AVX \
	-DRTE_MACHINE_CPUFLAG_RDRAND -DRTE_MACHINE_CPUFLAG_FSGSBASE \
	-DRTE_MACHINE_CPUFLAG_F16C -DRTE_MACHINE_CPUFLAG_AVX2

DPDK_C_Flags := -pthread $(DPDK_C_CPU_Flags) -include \
	$(RTE_SDK)/$(RTE_TARGET)/include/rte_config.h \
	-I$(RTE_SDK)/$(RTE_TARGET)/include

DPDK_Link_Flags := -L$(RTE_SDK)/$(RTE_TARGET)/lib -lrte_pipeline -lrte_table \
       	-lrte_port -lrte_pdump -lrte_distributor -lrte_ip_frag -lrte_meter \
	-lrte_sched  -lrte_lpm -Wl,--whole-archive -lrte_acl \
	-Wl,--no-whole-archive -lrte_jobstats -lrte_metrics -lrte_bitratestats \
	-lrte_latencystats -lrte_power -lrte_timer -lrte_efd -lrte_cfgfile \
	-Wl,--whole-archive -lrte_hash -lrte_vhost -lrte_kvargs -lrte_mbuf \
	-lrte_net -lrte_ethdev -lrte_cryptodev -lrte_eventdev -lrte_mempool \
	-lrte_mempool_ring -lrte_ring -lrte_eal -lrte_cmdline -lrte_reorder \
	-lrte_kni -lrte_mempool_stack -lrte_pmd_af_packet -lrte_pmd_ark \
	-lrte_pmd_avp -lrte_pmd_bnx2x -lz  -lrte_pmd_bond -lrte_pmd_cxgbe \
	-lrte_pmd_e1000 -lrte_pmd_ena -lrte_pmd_enic -lrte_pmd_fm10k \
	-lrte_pmd_i40e -lrte_pmd_ixgbe -lrte_pmd_kni -lrte_pmd_lio \
	-lrte_pmd_nfp -lrte_pmd_null -lrte_pmd_qede -lrte_pmd_ring \
	-lrte_pmd_sfc_efx -lrte_pmd_tap -lrte_pmd_thunderx_nicvf \
	-lrte_pmd_virtio -lrte_pmd_vhost -lrte_pmd_vmxnet3_uio \
	-lrte_pmd_null_crypto -lrte_pmd_crypto_scheduler \
	-lrte_pmd_skeleton_event -lrte_pmd_sw_event -lrte_pmd_octeontx_ssovf \
	-Wl,--no-whole-archive -lrt -lm -ldl -lpthread -lpcap

# TODO(Deli): config DPDK_C_Flags and DPDK_Link_Flags utilizing DPDK build system

WError_Flags := -W -Wall -Wstrict-prototypes -Wmissing-prototypes \
	-Wmissing-declarations -Wold-style-definition -Wpointer-arith \
	-Wcast-align -Wnested-externs -Wformat-security -Wundef \
	-Wwrite-strings -Werror
WError_Flags_Extra := -Wcast-qual -Wformat-nonliteral


Dpdk_App_Name := ip_pipeline
Native_Name := firewall_native

######## SGX SDK Settings ########

SGX_SDK ?= /opt/intel/sgxsdk
SGX_MODE ?= HW
SGX_ARCH ?= x64
SGX_DEBUG ?= 1

ifeq ($(shell getconf LONG_BIT), 32)
	SGX_ARCH := x86
else ifeq ($(findstring -m32, $(CXXFLAGS)), -m32)
	SGX_ARCH := x86
endif

ifeq ($(SGX_ARCH), x86)
	SGX_COMMON_CFLAGS := -m32
	SGX_LIBRARY_PATH := $(SGX_SDK)/lib
	SGX_ENCLAVE_SIGNER := $(SGX_SDK)/bin/x86/sgx_sign
	SGX_EDGER8R := $(SGX_SDK)/bin/x86/sgx_edger8r
else
	SGX_COMMON_CFLAGS := -m64
	SGX_LIBRARY_PATH := $(SGX_SDK)/lib64
	SGX_ENCLAVE_SIGNER := $(SGX_SDK)/bin/x64/sgx_sign
	SGX_EDGER8R := $(SGX_SDK)/bin/x64/sgx_edger8r
endif

ifeq ($(SGX_DEBUG), 1)
ifeq ($(SGX_PRERELEASE), 1)
$(error Cannot set SGX_DEBUG and SGX_PRERELEASE at the same time!!)
endif
endif

ifeq ($(SGX_DEBUG), 1)
        SGX_COMMON_CFLAGS += -O0 -g
else
        SGX_COMMON_CFLAGS += -O3
endif

######## App Settings ########

ifneq ($(SGX_MODE), HW)
	Urts_Library_Name := sgx_urts_sim
else
	Urts_Library_Name := sgx_urts
endif

Dpdk_App_Dir := App/ip_pipeline

App_C_Files := $(wildcard $(Dpdk_App_Dir)/*.c)
App_C_Files += $(wildcard $(Dpdk_App_Dir)/pipeline/*.c)
App_C_Files += $(wildcard App/*.c)
App_Cpp_Files := App/App.cpp
App_Include_Paths := -IApp -I$(Dpdk_App_Dir) -I$(Dpdk_App_Dir)/pipeline
App_Include_Paths += -I$(SGX_SDK)/include -IEnclave -IEnclave/dpdk

App_C_Flags := $(SGX_COMMON_CFLAGS) -fPIC -Wno-attributes $(App_Include_Paths)

# Three configuration modes - Debug, prerelease, release
#   Debug - Macro DEBUG enabled.
#   Prerelease - Macro NDEBUG and EDEBUG enabled.
#   Release - Macro NDEBUG enabled.
ifeq ($(SGX_DEBUG), 1)
        App_C_Flags += -DDEBUG -UNDEBUG -UEDEBUG
else ifeq ($(SGX_PRERELEASE), 1)
        App_C_Flags += -DNDEBUG -DEDEBUG -UDEBUG
else
        App_C_Flags += -DNDEBUG -UEDEBUG -UDEBUG
endif


App_C_Flags += -DENABLE_SGX $(DPDK_C_Flags) $(Native_Extra_CFlags)
# App_C_Flags += $(WError_Flags)
# App_C_Flags += $(WError_Flags_Extra)

App_Cpp_Flags := $(App_C_Flags) -std=c++11
App_Link_Flags := $(SGX_COMMON_CFLAGS) -L$(SGX_LIBRARY_PATH)
App_Link_Flags += -l$(Urts_Library_Name) $(DPDK_Link_Flags)

ifneq ($(SGX_MODE), HW)
	App_Link_Flags += -lsgx_uae_service_sim
else
	App_Link_Flags += -lsgx_uae_service
endif

App_C_Objects := $(App_C_Files:.c=.o)

App_Cpp_Objects := $(App_Cpp_Files:.cpp=.o)

App_Name := firewall_sgx

######## Enclave Settings ########

ifneq ($(SGX_MODE), HW)
	Trts_Library_Name := sgx_trts_sim
	Service_Library_Name := sgx_tservice_sim
else
	Trts_Library_Name := sgx_trts
	Service_Library_Name := sgx_tservice
endif
Crypto_Library_Name := sgx_tcrypto

Enclave_Cpp_Files := Enclave/Enclave.cpp
Enclave_C_Files := $(wildcard Enclave/ip_pipeline/*.c)
Enclave_C_Files += $(wildcard Enclave/dpdk/*/*.c)
Enclave_C_Files += $(wildcard Enclave/io/*.c)
Enclave_C_Files += $(wildcard Enclave/*.c)

Enclave_Include_Paths := -I$(SGX_SDK)/include -I$(SGX_SDK)/include/tlibc
Enclave_Include_Paths += -I$(SGX_SDK)/include/libcxx -IEnclave
Enclave_Include_Paths += -IEnclave/include/dpdk -IEnclave/include/system
Enclave_Include_Paths += -IEnclave/ip_pipeline -IEnclave/dpdk
Enclave_Include_Paths += -I$(Dpdk_App_Dir) -I$(Dpdk_App_Dir)/pipeline

CC_BELOW_4_9 := $(shell expr "`$(CC) -dumpversion`" \< "4.9")
ifeq ($(CC_BELOW_4_9), 1)
	Enclave_C_Flags := $(SGX_COMMON_CFLAGS) -nostdinc -fvisibility=hidden \
		-fpie -ffunction-sections -fdata-sections -fstack-protector
else
	Enclave_C_Flags := $(SGX_COMMON_CFLAGS) -nostdinc -fvisibility=hidden \
		-fpie -ffunction-sections -fdata-sections \
		-fstack-protector-strong
endif

Enclave_C_Flags += $(Enclave_Include_Paths)
Enclave_C_Flags += -DAPP_ENCLAVE -DENABLE_SGX -DRTE_LOG_LEVEL=RTE_LOG_DEBUG
# Enclave_C_Flags += -DRTE_SCHED_COLLECT_STATS
Enclave_C_Flags += $(DPDK_C_CPU_Flags)
Enclave_C_Flags += $(Enclave_Feature_Flags)

Enclave_Cpp_Flags := $(Enclave_C_Flags) -std=c++11 -nostdinc++

ifeq ($(SGX_MODE), HW)
Use_TCMalloc := -Wl,--whole-archive -lsgx_tcmalloc
endif

# To generate a proper enclave, it is recommended to follow below guideline to link the trusted libraries:
#    1. Link sgx_trts with the `--whole-archive' and `--no-whole-archive' options,
#       so that the whole content of trts is included in the enclave.
#    2. For other libraries, you just need to pull the required symbols.
#       Use `--start-group' and `--end-group' to link these libraries.
# Do NOT move the libraries linked with `--start-group' and `--end-group' within `--whole-archive' and `--no-whole-archive' options.
# Otherwise, you may get some undesirable errors.
Enclave_Link_Flags := $(SGX_COMMON_CFLAGS) \
	-Wl,--no-undefined -nostdlib -nodefaultlibs -nostartfiles \
	-L$(SGX_LIBRARY_PATH)  \
	-Wl,--whole-archive -l$(Trts_Library_Name) \
	$(Use_TCMalloc) \
	-Wl,--no-whole-archive -Wl,--start-group \
		-lsgx_tstdc -lsgx_tcxx \
		-l$(Crypto_Library_Name) \
		-l$(Service_Library_Name) \
	-Wl,--end-group \
	-Wl,-Bstatic -Wl,-Bsymbolic -Wl,--no-undefined \
	-Wl,-pie,-eenclave_entry -Wl,--export-dynamic  \
	-Wl,--defsym,__ImageBase=0 -Wl,--gc-sections   \
	-Wl,--version-script=Enclave/Enclave.lds

Enclave_Cpp_Objects := $(Enclave_Cpp_Files:.cpp=.o)
Enclave_C_Objects := $(Enclave_C_Files:.c=.o)

Enclave_Name := enclave.so
Signed_Enclave_Name := enclave.signed.so
Enclave_Config_File := Enclave/Enclave.config.xml

Edger8r_Search_Path := --search-path ../Enclave \
	--search-path $(SGX_SDK)/include \
	--search-path ../Enclave/dpdk

ifeq ($(SGX_MODE), HW)
ifeq ($(SGX_DEBUG), 1)
	Build_Mode = HW_DEBUG
else ifeq ($(SGX_PRERELEASE), 1)
	Build_Mode = HW_PRERELEASE
else
	Build_Mode = HW_RELEASE
endif
else
ifeq ($(SGX_DEBUG), 1)
	Build_Mode = SIM_DEBUG
else ifeq ($(SGX_PRERELEASE), 1)
	Build_Mode = SIM_PRERELEASE
else
	Build_Mode = SIM_RELEASE
endif
endif

.PHONY: all run bench kill

ifeq ($(Build_Mode), HW_RELEASE)
all: .config_$(Build_Mode)_$(SGX_ARCH) $(App_Name) $(Enclave_Name)
	@echo "The project has been built in release hardware mode."
	@echo "Please sign the $(Enclave_Name) first with your signing key before you run the $(App_Name) to launch and access the enclave."
	@echo "To sign the enclave use the command:"
	@echo "   $(SGX_ENCLAVE_SIGNER) sign -key <your key> -enclave $(Enclave_Name) -out <$(Signed_Enclave_Name)> -config $(Enclave_Config_File)"
	@echo "You can also sign the enclave using an external signing tool."
	@echo "To build the project in simulation mode set SGX_MODE=SIM. To build the project in prerelease mode set SGX_PRERELEASE=1 and SGX_MODE=HW."
else
all: .config_$(Build_Mode)_$(SGX_ARCH) $(App_Name) $(Signed_Enclave_Name)
ifeq ($(Build_Mode), HW_DEBUG)
	@echo "The project has been built in debug hardware mode."
else ifeq ($(Build_Mode), SIM_DEBUG)
	@echo "The project has been built in debug simulation mode."
else ifeq ($(Build_Mode), HW_PRERELEASE)
	@echo "The project has been built in pre-release hardware mode."
else ifeq ($(Build_Mode), SIM_PRERELEASE)
	@echo "The project has been built in pre-release simulation mode."
else
	@echo "The project has been built in release simulation mode."
endif
endif

run:
ifneq ($(Build_Mode), HW_RELEASE)
	@echo "RUN  =>  $(App_Name) [$(SGX_MODE)|$(SGX_ARCH), OK]"
endif

kill:
	@pkill -f $(App_Name)

######## Rate-Limiter App without SGX #######
native:
	@$(MAKE) -C $(Dpdk_App_Dir) -j \
		APP_EXTRA_INCLUDE_PATH=$(Current_Makefile_Dir)Include \
		EXTRA_CFLAGS="$(Native_Extra_CFlags)"
	@echo "MAKE => $@"
	@cp $(Dpdk_App_Dir)/build/$(Dpdk_App_Name) $(Native_Name)

######## App Objects ########

App/Enclave_u.c: $(SGX_EDGER8R) Enclave/Enclave.edl
	@cd App && $(SGX_EDGER8R) --untrusted ../Enclave/Enclave.edl \
		$(Edger8r_Search_Path)
	@echo "GEN  =>  $@"

App/Enclave_u.o: App/Enclave_u.c
	@$(CC) $(App_C_Flags) -c $< -o $@
	@echo "CC   <=  $<"

App/%.o: App/%.c
	@$(CC) $(App_C_Flags) -c $< -o $@
	@echo "CC   <=  $<"

App/%.o: App/%.cpp
	@$(CXX) $(App_Cpp_Flags) -c $< -o $@
	@echo "CXX  <=  $<"

$(App_Name): App/Enclave_u.o $(App_Cpp_Objects) $(App_C_Objects)
	@$(CXX) $^ -o $@ $(App_Link_Flags)
	@echo "LINK =>  $@"

.config_$(Build_Mode)_$(SGX_ARCH):
	@rm -f .config_* $(App_Name) $(Enclave_Name) $(Signed_Enclave_Name) \
		$(App_Cpp_Objects) App/Enclave_u.* $(Enclave_Cpp_Objects) \
		Enclave/Enclave_t.*
	@touch .config_$(Build_Mode)_$(SGX_ARCH)

######## Enclave Objects ########

Enclave/Enclave_t.c: $(SGX_EDGER8R) Enclave/Enclave.edl
	@cd Enclave && $(SGX_EDGER8R) --trusted ../Enclave/Enclave.edl \
		$(Edger8r_Search_Path)
	@echo "GEN  =>  $@"

Enclave/Enclave_t.o: Enclave/Enclave_t.c
	@$(CC) $(Enclave_C_Flags) -c $< -o $@
	@echo "CC   <=  $<"

Enclave/%.o: Enclave/%.cpp
	@$(CXX) $(Enclave_Cpp_Flags) -c $< -o $@
	@echo "CXX  <=  $<"

Enclave/%.o: Enclave/%.c
	@$(CC) $(Enclave_C_Flags) $(WError_Flags) -c $< -o $@
	@echo "CC   <=  $<"

.PHONY:
# Enclave/ip_pipeline/sketch.o:  Enclave/ip_pipeline/sketch.c
	# @$(CC) $(Enclave_C_Flags) -fopt-info-vec-optimized  $(WError_Flags) -c $< -o $@
	# @echo "CC   <=  $<"

$(Enclave_Name): Enclave/Enclave_t.o $(Enclave_Cpp_Objects) $(Enclave_C_Objects)
	@$(CXX) $^ -o $@ $(Enclave_Link_Flags)
	@echo "LINK =>  $@"

$(Signed_Enclave_Name): $(Enclave_Name)
	@$(SGX_ENCLAVE_SIGNER) sign -key Enclave/Enclave_private.pem \
		-enclave $(Enclave_Name) -out $@ -config $(Enclave_Config_File)
	@echo "SIGN =>  $@"

.PHONY: clean

clean:
	@rm -f .config_* $(App_Name) $(Enclave_Name) $(Signed_Enclave_Name) \
		$(App_Cpp_Objects) App/Enclave_u.* $(Enclave_Cpp_Objects) \
		Enclave/Enclave_t.* $(App_C_Objects) $(Enclave_C_Objects)
	@$(MAKE) -C $(Dpdk_App_Dir) clean
	@rm -rf $(Dpdk_App_Dir)/build $(Native_Name)
