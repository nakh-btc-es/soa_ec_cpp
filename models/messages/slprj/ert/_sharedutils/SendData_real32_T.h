//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: SendData_real32_T.h
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

#ifndef SendData_real32_T_h_
#define SendData_real32_T_h_
#include <stdint.h>

class SendData_real32_T
{
 public:
  virtual void SendData(const float *data, int32_t length, int32_t *status) = 0;
  virtual ~SendData_real32_T()
    = default;
};

#endif                                 // SendData_real32_T_h_

//
// File trailer for generated code.
//
// [EOF]
//
