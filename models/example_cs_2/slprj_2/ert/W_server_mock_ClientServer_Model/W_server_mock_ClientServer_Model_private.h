//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: W_server_mock_ClientServer_Model_private.h
//
// Code generated for Simulink model 'W_server_mock_ClientServer_Model'.
//
// Model version                  : 1.2
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Wed Sep 24 20:23:17 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives: Unspecified
// Validation result: Not run
//
#ifndef W_server_mock_ClientServer_Model_private_h_
#define W_server_mock_ClientServer_Model_private_h_
#include <stdbool.h>
#include <stdint.h>
#include "complex_types.h"
#include "W_server_mock_ClientServer_Model_types.h"

// Real-time Model Data Structure
struct w_tag_RTM_W_server_mock_ClientServer_Model_T {
  const char **errorStatus;
  const char* getErrorStatus() const;
  void setErrorStatus(const char* const aErrorStatus) const;
  const char** getErrorStatusPointer() const;
  void setErrorStatusPointer(const char** aErrorStatusPointer);
};

struct w_MdlrefDW_W_server_mock_ClientServer_Model_T {
  w_RT_MODEL_W_server_mock_ClientServer_Model_T rtm;
};

extern w_MdlrefDW_W_server_mock_ClientServer_Model_T
  w_W_server_mock_ClientServer_Model_MdlrefDW;

#endif                           // W_server_mock_ClientServer_Model_private_h_

//
// File trailer for generated code.
//
// [EOF]
//
