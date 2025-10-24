//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: oMessage_Model_types.h
//
// Code generated for Simulink model 'oMessage_Model'.
//
// Model version                  : 1.4
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Mon Sep 29 10:47:40 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives: Unspecified
// Validation result: Not run
//
#ifndef oMessage_Model_types_h_
#define oMessage_Model_types_h_
#include "rtwtypes.h"
#ifndef DEFINED_TYPEDEF_FOR_OutputDataInterface_
#define DEFINED_TYPEDEF_FOR_OutputDataInterface_

struct OutputDataInterface
{
  real_T DataC;
};

#endif

#ifndef DEFINED_TYPEDEF_FOR_InputDataInterface_
#define DEFINED_TYPEDEF_FOR_InputDataInterface_

struct InputDataInterface
{
  real_T DataA;
  real_T DataB;
};

#endif

#ifndef DEFINED_TYPEDEF_FOR_RecvData_InputDataInterfaceT_
#define DEFINED_TYPEDEF_FOR_RecvData_InputDataInterfaceT_

class RecvData_InputDataInterfaceT
{
 public:
  virtual void RecvData(InputDataInterface *data, int32_T length, int32_T
                        *status) = 0;
  virtual ~RecvData_InputDataInterfaceT()
    = default;
};

#endif

#ifndef DEFINED_TYPEDEF_FOR_SendData_OutputDataInterfaceT_
#define DEFINED_TYPEDEF_FOR_SendData_OutputDataInterfaceT_

class SendData_OutputDataInterfaceT
{
 public:
  virtual void SendData(const OutputDataInterface *data, int32_T length, int32_T
                        *status) = 0;
  virtual ~SendData_OutputDataInterfaceT()
    = default;
};

#endif
#endif                                 // oMessage_Model_types_h_

//
// File trailer for generated code.
//
// [EOF]
//
