#pragma once

#include <atomic>

namespace colakv {

class ServerEntry {
public:
    ServerEntry();
    virtual ~ServerEntry();

    virtual bool Start();
    virtual bool Run();
    virtual bool Shutdown();

protected:
    virtual bool StartServer() = 0;
    virtual void ShutdownServer() = 0;

private:
    bool ShouldStart();
    bool ShouldShutdown();

private:
    std::atomic<bool> started_;
};

}  // namespace colakv
