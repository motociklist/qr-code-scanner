#ifndef FLUTTER_MY_APPLICATION_H_
#define FLUTTER_MY_APPLICATION_H_

#include <flutter/flutter_engine.h>
#include <flutter/window_controller.h>
#include <memory>
#include <string>
#include <vector>

class MyApplication {
 public:
  MyApplication();
  ~MyApplication();

  // Disallow copy and assign.
  MyApplication(const MyApplication&) = delete;
  MyApplication& operator=(const MyApplication&) = delete;

  bool Initialize(const std::string& data_directory, const std::vector<std::string>& arguments);
  void Run();

 private:
  std::unique_ptr<flutter::FlutterEngine> engine_;
  std::unique_ptr<flutter::WindowController> window_controller_;
};

#endif  // FLUTTER_MY_APPLICATION_H_

