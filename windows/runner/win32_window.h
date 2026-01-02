#ifndef FLUTTER_WIN32_WINDOW_H_
#define FLUTTER_WIN32_WINDOW_H_

#include <windows.h>

#include <iosfwd>
#include <memory>
#include <string>

// A class abstraction for a high DPI-aware Win32 Window. Used in both
// fullscreen and windowed modes.
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates and shows a win32 window with |title|, |origin|, and |size|.
  // Returns true on success.
  bool CreateAndShow(const std::wstring& title, const Point& origin,
                     const Size& size);

  // Releases OS resources associated with window.
  void Destroy();

  // Inserts |content| into the window tree.
  void SetChildContent(HWND content);

  // Returns the backing Window handle to enable clients to set icon and
  // other window properties. Returns nullptr if the window has been destroyed.
  HWND GetHandle();

  // Returns true if the window is currently visible.
  bool IsVisible();

  // Returns the window DPI.
  int GetDpi();

  // Return the scale factor for the window.
  float GetScaleFactor();

  // Called when a key is pressed.
  virtual void OnKey(char32_t key, int scancode, int action, char32_t character,
                     bool extended, bool was_down);

  // Called when the window size is changed.
  virtual void OnResize(unsigned int width, unsigned int height);

  // Called when the window is closed.
  virtual void OnClose();

  // Called when the window is destroyed.
  virtual void OnDestroy();

 protected:
  // Override to handle window messages.
  virtual LRESULT MessageHandler(HWND window, UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) = 0;

 private:
  friend class WindowClassRegistrar;

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when creating a window.
  static LRESULT CALLBACK WndProc(HWND const window, UINT const message,
                                  WPARAM const wparam, LPARAM const lparam);

  // Retrieves a class instance pointer for |window|
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;

  // Registers a window class.
  static void RegisterWindowClass(HWND window);

  bool win32_window_class_registered_ = false;
  HWND window_handle_ = nullptr;
  int current_dpi_ = 0;
  float current_scale_factor_ = 1.0;
};

#endif  // FLUTTER_WIN32_WINDOW_H_

