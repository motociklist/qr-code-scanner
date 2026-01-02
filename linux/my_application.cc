#include "my_application.h"

#include <iostream>
#include <memory>
#include <vector>
#include <string>

#include "flutter/generated_plugin_registrant.h"

MyApplication::MyApplication() {}

MyApplication::~MyApplication() {}

bool MyApplication::Initialize(const std::string& data_directory, const std::vector<std::string>& arguments) {
  flutter::DartProject project(data_directory);
  project.set_dart_entrypoint_arguments(std::move(arguments));

  engine_ = std::make_unique<flutter::FlutterEngine>();
  if (!engine_->Start(project)) {
    return false;
  }

  RegisterPlugins(engine_.get());

  window_controller_ = std::make_unique<flutter::WindowController>(1280, 600);
  window_controller_->SetTitle("QR Code Scanner");

  return true;
}

void MyApplication::Run() {
  if (window_controller_) {
    window_controller_->Run();
  }
}

