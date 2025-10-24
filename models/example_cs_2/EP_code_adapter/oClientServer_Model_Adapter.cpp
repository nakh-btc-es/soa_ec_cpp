#include "oClientServer_Model.h"
#include "oClientServer_Model_types.h"
#include "sut_step.h"
#include "sut_ServerService_getDataC.h"
#include "sut_ServerService_setDataA.h"
#include "sut_ServerService_setDataB.h"
#include "ClientServiceInterface_ClientService_add.h"


/*********************************************************
**** Adapter to the Client Services, SUT, Server Services
**********************************************************/

// Derived class that overrides add
class ClientServiceImpl : public ClientServiceInterfaceT {
public:
    void add(real_T a, real_T b, real_T* result) override {
        if (result) {
            ClientServiceInterface_ClientService_add(a, b, result);
        }
    }
};
ClientServiceImpl newClientService;

//Instantiate model
ComponentNamespace::oClientServer_Model newModelObj(newClientService);

//Adapter to SWC Step function
void sut_step() {
  newModelObj.step();
}
//Adapter to SWC Init function
void sut_initialize() {
  newModelObj.initialize();
}

//Instantiation of Server service
ComponentNamespace::oClientServer_ModelServerServiceT newServerService(newModelObj);

//Adapters to Server services
void sut_ServerService_setDataA(double dataA) {
  newServerService.setDataA(dataA);
}
void sut_ServerService_setDataB(double dataB) {
  newServerService.setDataB(dataB);
}
double sut_ServerService_getDataC() {
  double val;
  newServerService.getDataC(&val);
  return val;
}



