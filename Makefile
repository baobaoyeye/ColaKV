
# OPT ?= -O2 -DNDEBUG # (A) Production use (optimized mode)
OPT ?= -g2 -Werror # (B) Debug mode, w/ full line-level debugging symbols
# OPT ?= -O2 -g2 -DNDEBUG # (C) Profiling mode: opt, but w/debugging symbols

include depends.mk
#CXX=/opt/compiler/gcc-4.8.2/bin/g++

INCLUDE_PATH = -I./src -I$(PROTOBUF_PATH)/include \
               -I$(GRPC_PATH)/include \
               -I$(ROCKSDB_PATH)/include \
               -I$(SNAPPY_PATH)/include \
               -I$(GFLAG_PATH)/include \

LDFLAGS = -L$(GRPC_PATH)/lib -lgrpc \
          -L$(PROTOBUF_PATH)/lib -lprotobuf \
          -L$(ROCKSDB_PATH)/lib -lrocksdb \
          -L$(SNAPPY_PATH)/lib -lsnappy \
          -L$(GFLAG_PATH)/lib -lgflags \
          -L$(GTEST_PATH)/lib -lgtest -lpthread -lz -lrt

SO_LDFLAGS += -rdynamic $(DEPS_LDPATH) $(SO_DEPS_LDFLAGS) -lpthread -lrt -lz -ldl \
	      -shared -Wl,--version-script,so-version-script # hide symbol of thirdparty libs

CXXFLAGS = -std=$(STD_FLAG) -Wall -fPIC $(OPT)

PROTO_FILE = $(wildcard src/proto/*.proto)
PROTO_SRC = $(patsubst %.proto,%.pb.cc,$(PROTO_FILE))
PROTO_HEADER = $(patsubst %.proto,%.pb.h,$(PROTO_FILE))
PROTO_OBJ = $(patsubst %.proto,%.pb.o,$(PROTO_FILE))

KV_NODE_SRC = $(wildcard src/kv_node/*.cc)
KV_NODE_OBJ = $(patsubst %.cc, %.o, $(KV_NODE_SRC))
KV_NODE_HEADER = $(wildcard src/kv_node/*.h)

RPC_SRC = $(wildcard src/rpc/*.cc)
RPC_OBJ = $(patsubst %.cc, %.o, $(RPC_SRC))

SDK_SRC = $(wildcard src/sdk/*.cc)
SDK_OBJ = $(patsubst %.cc, %.o, $(SDK_SRC))
SDK_HEADER = $(wildcard src/sdk/*.h)

CLIENT_OBJ = $(patsubst %.cc, %.o, $(wildcard src/client/*.cc))

FLAGS_OBJ = src/flags.o
OBJS = $(FLAGS_OBJ) $(RPC_OBJ) $(PROTO_OBJ)

LIBS = libcolakv.a
BIN = cola_client kv_node

TESTS = kv_node_test sdk_test region_test region_manger_test
TEST_OBJS = src/kv_node/test/kv_node_test.o \
			src/region/test/region_test.o \
			src/region_manager/test/region_manager_test.o \
			src/sdk/test/sdk_test.o 
UNITTEST_OUTPUT = ut/

all: $(BIN)
	@echo 'Done'

# Depends
$(KV_NODE_OBJ) $(PROTO_OBJ) $(SDK_OBJ): $(PROTO_HEADER)
$(KV_NODE_OBJ): $(KV_NODE_HEADER)
$(SDK_OBJ): $(SDK_HEADER)

# Targets

check: all $(TESTS)
	mkdir -p $(UNITTEST_OUTPUT)
	mv $(TESTS) $(UNITTEST_OUTPUT)
	cd $(UNITTEST_OUTPUT); for t in $(TESTS); do echo "***** Running $$t"; ./$$t || exit 1; done

kv_node_test: src/kv_node/test/kv_node_test.o src/kv_node/kv_node.o
	$(CXX) $^ $(OBJS) -o $@ $(LDFLAGS)

region_test: src/kv_node/test/region_test.o src/kv_node/region.o
	$(CXX) $^ $(OBJS) -o $@ $(LDFLAGS)

region_manager_test: src/kv_node/test/region_manager_test.o src/kv_node/region_manager.o
	$(CXX) $^ $(OBJS) -o $@ $(LDFLAGS)

sdk_test: src/sdk/test/sdk_test.o src/sdk/clinet.o src/sdk/update.o src/sdk/get.o src/sdk/scan.o
	$(CXX) $^ $(OBJS) -o $@ $(LDFLAGS)

cola_client: src/nameserver/test/kv_client.o $(SKD_OBJS)
	$(CXX) $^ -o $@ $(LDFLAGS)

%.pb.h %.pb.cc: %.proto
	$(PROTOC) --proto_path=./src/proto/ --proto_path=/usr/local/include --cpp_out=./src/proto/ $<
src/version.cc: FORCE
	bash build_version.sh

.PHONY: FORCE
FORCE:

clean:
	rm -rf $(KV_NODE_OBJ) $(SDK_OBJ) $(CLIENT_OBJ) $(OBJS) $(TEST_OBJS)
	rm -rf $(PROTO_SRC) $(PROTO_HEADER)
	rm -rf $(UNITTEST_OUTPUT)

install:
	rm -rf output
	mkdir -p output/include
	mkdir -p output/lib
	mkdir -p output/bin
	cp -f src/sdk/client.h src/sdk/update.h src/ output/include/
	cp -f cola_client output/bin/
	touch output/cola.flag

.PHONY: test
test:
	cd sandbox; ./small_test.sh; ./small_test.sh raft; ./small_test.sh master_slave
