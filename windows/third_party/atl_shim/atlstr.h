// Minimal atlstr.h shim.
//
// flutter_secure_storage_windows only uses the ATL string conversion helpers
// CA2W (UTF-8 -> UTF-16) and CW2A (UTF-16 -> UTF-8). The full ATL headers are
// not shipped with the "Desktop development with C++" build-tools workload on
// this machine, so we provide just enough here to satisfy the plugin.
//
// This file is intentionally tiny and only implements what the plugin needs:
//   - A public m_psz member (LPCWSTR / LPCSTR).
//   - Implicit conversion operators used in a couple of call sites.

#pragma once

#ifndef __ATLSTR_H_SHIM__
#define __ATLSTR_H_SHIM__

#include <windows.h>

#include <cstring>

class CA2W {
 public:
  explicit CA2W(LPCSTR psz, UINT /*cp*/ = CP_UTF8) : m_psz(nullptr) {
    if (psz == nullptr) return;
    const int len = ::MultiByteToWideChar(CP_UTF8, 0, psz, -1, nullptr, 0);
    if (len == 0) return;
    m_psz = new WCHAR[len];
    ::MultiByteToWideChar(CP_UTF8, 0, psz, -1, m_psz, len);
  }

  ~CA2W() { delete[] m_psz; }

  CA2W(const CA2W&) = delete;
  CA2W& operator=(const CA2W&) = delete;

  operator LPWSTR() const { return m_psz; }
  operator LPCWSTR() const { return m_psz; }

  LPWSTR m_psz;
};

class CW2A {
 public:
  explicit CW2A(LPCWSTR psz, UINT /*cp*/ = CP_UTF8) : m_psz(nullptr) {
    if (psz == nullptr) return;
    const int len =
        ::WideCharToMultiByte(CP_UTF8, 0, psz, -1, nullptr, 0, nullptr, nullptr);
    if (len == 0) return;
    m_psz = new CHAR[len];
    ::WideCharToMultiByte(CP_UTF8, 0, psz, -1, m_psz, len, nullptr, nullptr);
  }

  ~CW2A() { delete[] m_psz; }

  CW2A(const CW2A&) = delete;
  CW2A& operator=(const CW2A&) = delete;

  operator LPSTR() const { return m_psz; }
  operator LPCSTR() const { return m_psz; }

  LPSTR m_psz;
};

#endif  // __ATLSTR_H_SHIM__
