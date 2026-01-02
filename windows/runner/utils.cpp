#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE* unused;
    ::freopen_s(&unused, "CONOUT$", "w", stdout);
    ::freopen_s(&unused, "CONOUT$", "w", stderr);
    ::freopen_s(&unused, "CONIN$", "r", stdin);
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;
  command_line_arguments.reserve(argc - 1);
  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    // Convert the UTF-16 argument to UTF-8.
    int size = ::WideCharToMultiByte(CP_UTF8, 0, argv[i], -1, nullptr, 0,
                                     nullptr, nullptr);
    std::string utf8_argument(size, '\0');
    if (size > 0) {
      ::WideCharToMultiByte(CP_UTF8, 0, argv[i], -1, &utf8_argument[0], size,
                            nullptr, nullptr);
    }
    command_line_arguments.push_back(utf8_argument);
  }

  ::LocalFree(argv);
  return command_line_arguments;
}

