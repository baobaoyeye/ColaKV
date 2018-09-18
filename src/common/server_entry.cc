#include <time.h>

#include "common/server_entry.h"

namespace colakv {

ServerEntry::ServerEntry() : started_(false) {}

ServerEntry::~ServerEntry() {}

bool ServerEntry::Start() {
  if (ShouldStart()) {
    return StartServer();
  }
  return false;
}

bool ServerEntry::Run() {
  // sleep 1s
  timespec ts = {1, 0};
  nanosleep(&ts, &ts);
  return true;
}

bool ServerEntry::Shutdown() {
  if (ShouldShutdown()) {
    ShutdownServer();
    return true;
  }
  return false;
}

bool ServerEntry::ShouldStart() {
  bool has_started = false;
  return started_.compare_exchange_strong(has_started, true);
}

bool ServerEntry::ShouldShutdown() {
  bool has_shutdown = true;
  return started_.compare_exchange_strong(has_shutdown, false);
}

}  // namespace colakv
