//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: W_server_mock_ClientServer_Model.h
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
#ifndef W_server_mock_ClientServer_Model_h_
#define W_server_mock_ClientServer_Model_h_
#include <stdbool.h>
#include <stdint.h>
#include <cmath>
#include "complex_types.h"
#include "W_server_mock_ClientServer_Model_types.h"
#include "ClientServiceInterface_ClientService_add.h"

//
//  Exported States
//
//  Note: Exported states are block states with an exported global
//  storage class designation.  Code generation will declare the memory for these
//  states and exports their symbols.
//

extern double ClientService_add_DataA_In;// Simulink.Signal object 's_CC278'
extern double ClientService_add_DataB_In;// Simulink.Signal object 's_D6868'
extern double ClientService_add_DataD_Out;// Simulink.Signal object 's_DAA18'
extern void ClientServiceInterface_ClientService_add(double rtu_DataA, double
  rtu_DataB, double *rty_DataD);

// Model reference registration function
extern void W_server_mock_ClientServer_Model_initialize(const char
  **rt_errorStatus);

//-
//  The generated code includes comments that allow you to trace directly
//  back to the appropriate location in the model.  The basic format
//  is <system>/block_name, where system is the system number (uniquely
//  assigned by Simulink) and block_name is the name of the block.
//
//  Use the MATLAB hilite_system command to trace the generated code back
//  to the model.  For example,
//
//  hilite_system('<S3>')    - opens system 3
//  hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
//
//  Here is the system hierarchy for this model
//
//  '<Root>' : 'W_server_mock_ClientServer_Model'
//  '<S1>'   : 'W_server_mock_ClientServer_Model/Mock_ClientServiceInterface_ClientService_add'

#endif                                 // W_server_mock_ClientServer_Model_h_

//
// File trailer for generated code.
//
// [EOF]
//
