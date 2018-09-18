#pragma once

#include <grpc++/grpc++.h>

namespace colakv {
namespace rpc {

class RequestHandler {
     public:
        RequestHandler(grpc::ServerCompletionQueue* cq)
            : cq_(cq) {}

        virtual ~RequestHandler() {}

        virtual void start() = 0;
        virtual void process() = 0;
        virtual void cleanup() = 0;

        void proceed() {
            if (status_ == CREATE) {
                start();
                status_ = PROCESS;
            } else if (status_ == PROCESS) {
                process();
                status_ = FINISH;
            } else {
                GPR_ASSERT(status_ == FINISH);
                cleanup();
            }
        }

     protected:
        grpc::ServerContext ctx_;
        grpc::ServerCompletionQueue* cq_;
        enum CallStatus { CREATE, PROCESS, FINISH };
        CallStatus status_;  // The current serving state.
    };

}  // namespace rpc
}  // namespace colakv
