#ifndef FLUTTER_WINDOW_UTILS_H_
#define FLUTTER_WINDOW_UTILS_H_

#include <windows.h>
#include <string>
#include <vector>

// Creates and attaches a console to the process.
void CreateAndAttachConsole();

// Gets command line arguments.
std::vector<std::string> GetCommandLineArguments();

#endif  // FLUTTER_WINDOW_UTILS_H_

