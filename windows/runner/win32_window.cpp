#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>
#include <string>
#include <iostream>

namespace {

// The Windows DPI scale factor.
// A value of 1.0 means 96 DPI, which is the baseline DPI.
// A value of 1.5 means 144 DPI, etc.
float GetScaleFactor() {
  return static_cast<float>(GetDpiForSystem()) / 96.0f;
}

// Manages the Win32Window's window class registration.
class WindowClassRegistrar {
 public:
  ~WindowClassRegistrar() = default;

  // Returns the singleton registrar instance.
  static WindowClassRegistrar* GetInstance() {
    if (!instance_) {
      instance_ = new WindowClassRegistrar();
    }
    return instance_;
  }

  // Returns the name of the window class, registering the class if it hasn't
  // previously been registered.
  const wchar_t* GetWindowClass();

  // Unregisters the window class. Should only be called if there are no
  // instances of the window.
  void UnregisterWindowClass();

 private:
  WindowClassRegistrar() = default;

  static WindowClassRegistrar* instance_;

  bool class_registered_ = false;
};

WindowClassRegistrar* WindowClassRegistrar::instance_ = nullptr;

const wchar_t* WindowClassRegistrar::GetWindowClass() {
  if (!class_registered_) {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = L"FLUTTER_RUNNER_WIN32_WINDOW";
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = Win32Window::WndProc;
    RegisterClass(&window_class);
    class_registered_ = true;
  }
  return L"FLUTTER_RUNNER_WIN32_WINDOW";
}

void WindowClassRegistrar::UnregisterWindowClass() {
  if (!class_registered_) {
    return;
  }

  UnregisterClass(L"FLUTTER_RUNNER_WIN32_WINDOW", nullptr);
  class_registered_ = false;
  WindowClassRegistrar::instance_ = nullptr;
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::RegisterWindowClass(HWND window) {
  WindowClassRegistrar::GetInstance()->GetWindowClass();
}

Win32Window::Win32Window() {
  RegisterWindowClass(nullptr);
}

Win32Window::~Win32Window() {
  Destroy();
}

bool Win32Window::CreateAndShow(const std::wstring& title, const Point& origin,
                                 const Size& size) {
  Destroy();

  const wchar_t* window_class =
      WindowClassRegistrar::GetInstance()->GetWindowClass();

  const POINT target_point = {static_cast<LONG>(origin.x),
                              static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / 96.0;

  HWND window = CreateWindow(
      window_class, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
      static_cast<int>(origin.x * scale_factor), static_cast<int>(origin.y * scale_factor),
      static_cast<int>(size.width * scale_factor), static_cast<int>(size.height * scale_factor),
      nullptr, nullptr, GetModuleHandle(nullptr), this);

  if (!window) {
    return false;
  }

  return OnCreate();
}

void Win32Window::Destroy() {
  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
}

void Win32Window::SetChildContent(HWND content) {
  window_handle_ = content;
  SetWindowLongPtr(content, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
  SetWindowPos(content, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
  current_scale_factor_ = GetScaleFactor();
}

HWND Win32Window::GetHandle() {
  return window_handle_;
}

void Win32Window::OnResize(unsigned int width, unsigned int height) {}

void Win32Window::OnClose() {}

void Win32Window::OnDestroy() {}

void Win32Window::OnKey(char32_t key, int scancode, int action,
                        char32_t character, bool extended, bool was_down) {}

bool Win32Window::IsVisible() {
  return window_handle_ && IsWindowVisible(window_handle_);
}

int Win32Window::GetDpi() {
  return current_dpi_ = GetDpiForWindow(window_handle_);
}

float Win32Window::GetScaleFactor() {
  return current_scale_factor_;
}

LRESULT CALLBACK Win32Window::WndProc(HWND const window, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window*>(window_struct->lpCreateParams);
    that->window_handle_ = window;
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam,
                             LPARAM const lparam) {
  switch (message) {
    case WM_DESTROY:
      window_handle_ = nullptr;
      OnDestroy();
      return 0;

    case WM_CLOSE:
      OnClose();
      return 0;

    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      return 0;
    }
    case WM_SIZE:
      OnResize(LOWORD(lparam), HIWORD(lparam));
      break;
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

