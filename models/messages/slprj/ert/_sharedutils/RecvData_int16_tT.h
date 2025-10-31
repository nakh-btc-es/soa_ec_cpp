//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: RecvData_int16_tT.h
//
// Code generated for Simulink model 'messageModel'.
//
// Model version                  : 1.29
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Fri Oct 31 17:00:45 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives:
//    1. Execution efficiency
//    2. Traceability
// Validation result: Not run
//

#ifndef RecvData_int16_tT_h_
#define RecvData_int16_tT_h_
#include <stdint.h>

class RecvData_int16_tT
{
 public:
  virtual void RecvData(int16_t *data, int32_t length, int32_t *status) = 0;
  virtual ~RecvData_int16_tT()
    = default;
};

#endif                                 // RecvData_int16_tT_h_

//
// File trailer for generated code.
//
// [EOF]
//
