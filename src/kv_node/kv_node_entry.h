#pragma once 

#include <memory>
#include "kv_node/kv_node_impl.h"
#include "kv_node/kv_node_remote.h"
#include "common/server_entry.h"

namespace colakv {
namespace kv_node {

DECLARE_int32(rpc_handle_threads);

class KvNodeImpl;
class KvNodeRemote;

class KvNodeEntry : public ServerEntry {
 public:
  KvNodeEntry();
  ~KvNodeEntry();

  bool StartServer() {
    std::string server_address("0.0.0.0:50051");

    ServerBuilder builder;
    // Listen on the given address without any authentication mechanism.
    builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
    // Register "service_" as the instance through which we'll communicate with
    // clients. In this case it corresponds to an *asynchronous* service.
    builder.RegisterService(&service_);
    // Get hold of the completion queue used for the asynchronous communication
    // with the gRPC runtime.
    cq_ = builder.AddCompletionQueue();
    // Finally assemble the server.
    server_ = builder.BuildAndStart();
    std::cout << "Server listening on " << server_address << std::endl;

    // handle not in main thread, always in another thread
    HandleRpcs(FLAGS_rpc_handle_threads);
  }

  bool Run() {
	ServerEntry::Run();
	LOG(INFO) << "print some statistic infomations"; 
  }

  void ShutdownServer() { 
    server_->Shutdown();
    // Always shutdown the completion queue after the server.
    cq_->Shutdown();	
  }

  void MulitThreadHandleRpcs(int32_t rpc_handle_thread_cnt) {
	for (int32_t i = 0; i < rpc_handle_thread_cnt; ++i) {
		rpc_headle_threads_.emplace_back([](void* lparam) {
	        KvNodeEntry* entry = (KvNodeEntry*)lparam;
            entry->HandleRpcs();
		}, (void*)this);
	}
  }

  void HandleRpcs() {
		// Spawn a new CallData instance to serve new clients.
		new CallData(&service_, cq_.get());
		void* tag;  // uniquely identifies a request.
		bool ok;
		while (true) {
			// Block waiting to read the next event from the completion queue. The
			// event is uniquely identified by its tag, which in this case is the
			// memory address of a CallData instance.
			// The return value of Next should always be checked. This return value
			// tells us whether there is any kind of event or cq_ is shutting down.
			GPR_ASSERT(cq_->Next(&tag, &ok));
			GPR_ASSERT(ok);
			static_cast<CallData*>(tag)->Proceed();
		}
	}
 private:
  std::shared_ptr<KvNodeImpl> kv_node_impl_;
  std::unique_ptr<ServerCompletionQueue> cq_;
  Greeter::AsyncService service_;
  KvNodeService* kv_node_service_;
  std::unique_ptr<Server> server_;
  std::vector<std::thread> rpc_headle_threads_;
};

}  // namespace kv_node
}  // namespace colakv
