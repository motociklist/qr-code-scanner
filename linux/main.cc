#include <flutter/dart_project.h>
#include <flutter/flutter_engine.h>
#include <flutter/window_controller.h>
#include <linux/limits.h>
#include <unistd.h>

#include <iostream>
#include <vector>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "my_application.h"

namespace {

// Returns the path of the directory containing this executable, or empty string
// if the directory cannot be found.
std::string GetExecutableDirectory() {
  std::vector<char> buffer(PATH_MAX);
  ssize_t length = readlink("/proc/self/exe", buffer.data(), buffer.size());
  if (length > 0) {
    std::string executable_path(buffer.data(), length);
    size_t last_separator_pos = executable_path.find_last_of('/');
    if (last_separator_pos != std::string::npos) {
      return executable_path.substr(0, last_separator_pos);
    }
  }
  return std::string();
}

}  // namespace

int main(int argc, char* argv[]) {
  // Get the absolute path to the directory containing this executable.
  std::string base_directory = GetExecutableDirectory();
  if (base_directory.empty()) {
    base_directory = ".";
  }
  std::string data_directory = base_directory + "/data";

  // Arguments for the Flutter Engine.
  std::vector<std::string> arguments;
  for (int i = 1; i < argc; i++) {
    arguments.push_back(argv[i]);
  }

  MyApplication app;
  if (!app.Initialize(data_directory, arguments)) {
    return EXIT_FAILURE;
  }

  app.Run();

  return EXIT_SUCCESS;
}

