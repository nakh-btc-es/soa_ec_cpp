//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: oClientServer_Model.h
//
// Code generated for Simulink model 'oClientServer_Model'.
//
// Model version                  : 1.13
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Sun Sep 28 22:06:31 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives: Unspecified
// Validation result: Not run
//
#ifndef oClientServer_Model_h_
#define oClientServer_Model_h_
#include "rtwtypes.h"
#include "ClientServiceInterfaceT.h"
#include "oClientServer_Model_types.h"
#include "ServerServiceInterfaceT.h"

//
//  Exported States
//
//  Note: Exported states are block states with an exported global
//  storage class designation.  Code generation will declare the memory for these
//  states and exports their symbols.
//

extern real_T DataD_Display;          // Simulink.Signal object 'DataD_Display'

// Class declaration for model oClientServer_Model
namespace ComponentNamespace
{
  // Forward declaration
  class oClientServer_Model;
  class oClientServer_ModelServerServiceT : public ServerServiceInterfaceT
  {
    // public data and function members
   public:
    oClientServer_ModelServerServiceT(oClientServer_Model &aProvider);
    virtual void getDataC(real_T *DataC);
    virtual void setDataA(real_T DataA);
    virtual void setDataB(real_T DataB);

    // private data and function members
   private:
    oClientServer_Model &oClientServer_Model_mProvider;
  };

  class oClientServer_Model final
  {
   public:
    // Block signals (default storage)
    struct B_oClientServer_Model_T {
      real_T DataA;                    // '<S4>/DataA'
      real_T TmpSignalConversionAtDataAOutpo;// '<S4>/DataA'
      real_T DataB;                    // '<S4>/DataB'
      real_T TmpSignalConversionAtDataBOutpo;// '<S4>/DataB'
      real_T FunctionCaller;           // '<S4>/Function Caller'
      real_T TmpSignalConversionAtDataDInpor;// '<S4>/Function Caller'
      real_T DataC;
      real_T DataC_n;
      real_T DataA_c;                  // '<S2>/DataA'
      real_T TmpSignalConversionAtDataAOut_b;// '<S2>/DataA'
      real_T DataB_a;                  // '<S1>/DataB'
      real_T TmpSignalConversionAtDataBOut_k;// '<S1>/DataB'
      real_T DataC_d;                  // '<S5>/Chart'
      real_T DataD;                    // '<S5>/Chart'
    };

    // Real-time Model Data Structure
    struct RT_MODEL_oClientServer_Model_T {
      const char_T * volatile errorStatus;
      const char_T* getErrorStatus() const;
      void setErrorStatus(const char_T* const volatile aErrorStatus);
    };

    // Copy Constructor
    oClientServer_Model(oClientServer_Model const&) = delete;

    // Assignment Operator
    oClientServer_Model& operator= (oClientServer_Model const&) & = delete;

    // Move Constructor
    oClientServer_Model(oClientServer_Model &&) = delete;

    // Move Assignment Operator
    oClientServer_Model& operator= (oClientServer_Model &&) = delete;

    // Real-Time Model get method
    oClientServer_Model::RT_MODEL_oClientServer_Model_T * getRTM();

    // model step function
    void callAdd(const real_T rtu_DataA, const real_T rtu_DataB, real_T
                 *rty_DataD);

    // Constructor
    oClientServer_Model(ClientServiceInterfaceT &ClientService_arg);

    // Block signals
    B_oClientServer_Model_T oClientServer_Model_B;
    oClientServer_ModelServerServiceT ServerService;
    ClientServiceInterfaceT &ClientService;

    // model initialize function
    static void initialize();

    // model service function
    void setDataB(real_T rtu_DataB);

    // model service function
    void setDataA(real_T rtu_DataA);

    // model service function
    void getDataC(real_T *rty_DataC);

    // model step function
    void step();

    // model terminate function
    static void terminate();

    // Destructor
    ~oClientServer_Model();

    // Service port get method
    ServerServiceInterfaceT & get_ServerService();
   private:
    // Real-Time Model
    RT_MODEL_oClientServer_Model_T oClientServer_Model_M;
  };
}

//-
//  These blocks were eliminated from the model due to optimizations:
//
//  Block '<S5>/Display' : Unused code path elimination


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
//  '<Root>' : 'oClientServer_Model'
//  '<S1>'   : 'oClientServer_Model/Simulink Function'
//  '<S2>'   : 'oClientServer_Model/Simulink Function1'
//  '<S3>'   : 'oClientServer_Model/Simulink Function2'
//  '<S4>'   : 'oClientServer_Model/Simulink Function3'
//  '<S5>'   : 'oClientServer_Model/Subsystem'
//  '<S6>'   : 'oClientServer_Model/Subsystem/Chart'

#endif                                 // oClientServer_Model_h_

//
// File trailer for generated code.
//
// [EOF]
//
