#include <memory>
#include <signal.h>

#include <gflags/gflags.h>
#include <glog/logging.h>

#include "common/server_entry.h"

DECLARE_string(log_dir);
DECLARE_string(log_prefix);

volatile sig_atomic_t g_quit = 0;

static void SignalIntHandler(int sig) { g_quit = 1; }

void SetupLog(const std::string& name) {
  std::string program_name = "colakv";
  if (!name.empty()) {
    program_name = name;
  }

  std::string log_filename = FLAGS_log_dir + "/" + program_name + ".INFO.";
  std::string wf_filename = FLAGS_log_dir + "/" + program_name + ".WARNING.";
  google::SetLogDestination(google::INFO, log_filename.c_str());
  google::SetLogDestination(google::WARNING, wf_filename.c_str());
  google::SetLogDestination(google::ERROR, "");
  google::SetLogDestination(google::FATAL, "");

  google::SetLogSymlink(google::INFO, program_name.c_str());
  google::SetLogSymlink(google::WARNING, program_name.c_str());
  google::SetLogSymlink(google::ERROR, "");
  google::SetLogSymlink(google::FATAL, "");
}

extern std::string GetServerEntryName();
extern colakv::ServerEntry* GetServerEntry();

int main(int argc, char** argv) {
  ::google::ParseCommandLineFlags(&argc, &argv, true);
  ::google::InitGoogleLogging(argv[0]);

  if (FLAGS_log_prefix.empty()) {
    FLAGS_log_prefix = GetServerEntryName();
    if (FLAGS_log_prefix.empty()) {
      FLAGS_log_prefix = "colakv";
    }
  }
  SetupLog(FLAGS_log_prefix);

  if (argc > 1) {
    std::string ext_cmd = argv[1];
    if (ext_cmd == "version") {
	  std::cout << "v0.9.0" << std::endl;
      return 0;
    }
  }

  signal(SIGINT, SignalIntHandler);
  signal(SIGTERM, SignalIntHandler);

  std::unique_str<colakv::ServerEntry> entry(GetServerEntry());
  if (entry.get() == NULL) {
    return -1;
  }

  if (!entry->Start()) {
    return -1;
  }

  while (!g_quit) {
    if (!entry->Run()) {
      LOG(ERROR) << "Server run error ,and then exit now ";
      break;
    }
  }
  if (g_quit) {
    LOG(INFO) << "received interrupt signal from user, will stop";
  }

  if (!entry->Shutdown()) {
    return -1;
  }

  return 0;
}
