#include "oMessage_Model.h"
#include "oMessage_Model_types.h"

namespace BTC {
  namespace EPWrapper_oMessage_Model {

    ComponentNamespace::oMessage_Model model;

    struct B_oMessage_Model_T {
      InputDataInterface Receive;      // '<Root>/Receive'
      OutputDataInterface BusCreator;  // '<Root>/Bus Creator'
    };
    // External inputs
    ExtU_oMessage_Model_T oMessage_Model_U;
    // External outputs
    ExtY_oMessage_Model_T oMessage_Model_Y;

    void main_step() {
      // Input interface
      model.setInputData(oMessage_Model_U.Receive);

      // Calling the method under test.
      model.step();

      //Output interface
      oSignal_Model_Y.OutputData = model.getOutputData();
    }

  }
}
