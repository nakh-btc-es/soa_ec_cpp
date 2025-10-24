#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "../oMessage_Model_ert_rtw/oMessage_Model.h"
#include "../oMessage_Model_ert_rtw/oMessage_Model_types.h"

using namespace ComponentNamespace;
using ::testing::_;
using ::testing::Return;
using ::testing::SetArgPointee;
using ::testing::DoAll;

// Mock class for RecvData_InputDataInterfaceT
class MockRecvDataInterface : public RecvData_InputDataInterfaceT {
public:
    MOCK_METHOD(void, RecvData, (InputDataInterface* data, int32_T length, int32_T* status), (override));
};

// Mock class for SendData_OutputDataInterfaceT
class MockSendDataInterface : public SendData_OutputDataInterfaceT {
public:
    MOCK_METHOD(void, SendData, (const OutputDataInterface* data, int32_T length, int32_T* status), (override));
};

// Test fixture class
class oMessageModelTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Create mock objects
        mockRecvData = std::make_unique<MockRecvDataInterface>();
        mockSendData = std::make_unique<MockSendDataInterface>();
        
        // Create the model instance
        model = std::make_unique<oMessage_Model>(*mockRecvData, *mockSendData);
    }

    void TearDown() override {
        model.reset();
        mockSendData.reset();
        mockRecvData.reset();
    }

    // Helper method to set up input data
    void SetupInputData(double dataA, double dataB, int32_T status = 1) {
        InputDataInterface inputData;
        inputData.DataA = dataA;
        inputData.DataB = dataB;
        
        EXPECT_CALL(*mockRecvData, RecvData(_, sizeof(InputDataInterface), _))
            .WillOnce(DoAll(
                SetArgPointee<0>(inputData),
                SetArgPointee<2>(status)
            ));
    }

    // Helper method to verify output data
    void ExpectOutputData(double expectedDataC, int32_T expectedStatus = 1) {
        EXPECT_CALL(*mockSendData, SendData(_, sizeof(OutputDataInterface), _))
            .WillOnce([expectedDataC, expectedStatus](const OutputDataInterface* data, int32_T length, int32_T* status) {
                EXPECT_DOUBLE_EQ(data->DataC, expectedDataC);
                *status = expectedStatus;
            });
    }

protected:
    std::unique_ptr<MockRecvDataInterface> mockRecvData;
    std::unique_ptr<MockSendDataInterface> mockSendData;
    std::unique_ptr<oMessage_Model> model;
};

// Test Cases

TEST_F(oMessageModelTest, ConstructorInitializesCorrectly) {
    // Test that the constructor doesn't throw and model is properly initialized
    EXPECT_NE(model, nullptr);
    EXPECT_NE(model->getRTM(), nullptr);
}

TEST_F(oMessageModelTest, InitializeMethodExecutesWithoutError) {
    // Test static initialize method
    EXPECT_NO_THROW(oMessage_Model::initialize());
}

TEST_F(oMessageModelTest, TerminateMethodExecutesWithoutError) {
    // Test static terminate method
    EXPECT_NO_THROW(oMessage_Model::terminate());
}

TEST_F(oMessageModelTest, StepWithDataAGreaterThan5_PerformsAddition) {
    // Test case: DataA > 5.0, should perform addition (DataA + DataB)
    double dataA = 10.0;
    double dataB = 3.5;
    double expectedResult = dataA + dataB; // 13.5
    
    SetupInputData(dataA, dataB);
    ExpectOutputData(expectedResult);
    
    model->step();
}

TEST_F(oMessageModelTest, StepWithDataAEqualTo5_PerformsMultiplication) {
    // Test case: DataA = 5.0, should perform multiplication (DataA * DataB)
    double dataA = 5.0;
    double dataB = 4.0;
    double expectedResult = dataA * dataB; // 20.0
    
    SetupInputData(dataA, dataB);
    ExpectOutputData(expectedResult);
    
    model->step();
}

TEST_F(oMessageModelTest, StepWithDataALessThan5_PerformsMultiplication) {
    // Test case: DataA < 5.0, should perform multiplication (DataA * DataB)
    double dataA = 2.5;
    double dataB = 6.0;
    double expectedResult = dataA * dataB; // 15.0
    
    SetupInputData(dataA, dataB);
    ExpectOutputData(expectedResult);
    
    model->step();
}

TEST_F(oMessageModelTest, StepWithZeroValues) {
    // Test edge case: zero values
    double dataA = 0.0;
    double dataB = 0.0;
    double expectedResult = 0.0; // 0 * 0 = 0
    
    SetupInputData(dataA, dataB);
    ExpectOutputData(expectedResult);
    
    model->step();
}

TEST_F(oMessageModelTest, StepWithNegativeValues) {
    // Test with negative values
    double dataA = -3.0;
    double dataB = 2.0;
    double expectedResult = dataA * dataB; // -6.0 (since -3 < 5)
    
    SetupInputData(dataA, dataB);
    ExpectOutputData(expectedResult);
    
    model->step();
}

TEST_F(oMessageModelTest, StepWithLargePositiveValues) {
    // Test with large positive values
    double dataA = 100.0;
    double dataB = 50.0;
    double expectedResult = dataA + dataB; // 150.0 (since 100 > 5)
    
    SetupInputData(dataA, dataB);
    ExpectOutputData(expectedResult);
    
    model->step();
}

TEST_F(oMessageModelTest, ErrorStatusManagement) {
    // Test error status functionality
    auto* rtm = model->getRTM();
    
    // Initially should have no error
    EXPECT_EQ(rtm->getErrorStatus(), nullptr);
    
    // Set an error status
    const char* testError = "Test Error";
    rtm->setErrorStatus(testError);
    
    // Verify error status is set
    EXPECT_STREQ(rtm->getErrorStatus(), testError);
    
    // Clear error status
    rtm->setErrorStatus(nullptr);
    EXPECT_EQ(rtm->getErrorStatus(), nullptr);
}

TEST_F(oMessageModelTest, MultipleStepCalls) {
    // Test multiple consecutive step calls
    
    // First step: DataA > 5
    {
        SetupInputData(8.0, 2.0);
        ExpectOutputData(10.0); // 8 + 2
        model->step();
    }
    
    // Second step: DataA < 5
    {
        SetupInputData(3.0, 4.0);
        ExpectOutputData(12.0); // 3 * 4
        model->step();
    }
    
    // Third step: DataA > 5
    {
        SetupInputData(7.0, 1.5);
        ExpectOutputData(8.5); // 7 + 1.5
        model->step();
    }
}

// Boundary value tests
TEST_F(oMessageModelTest, BoundaryValueTest_DataAJustAbove5) {
    double dataA = 5.0001;
    double dataB = 3.0;
    double expectedResult = dataA + dataB;
    
    SetupInputData(dataA, dataB);
    ExpectOutputData(expectedResult);
    
    model->step();
}

TEST_F(oMessageModelTest, BoundaryValueTest_DataAJustBelow5) {
    double dataA = 4.9999;
    double dataB = 3.0;
    double expectedResult = dataA * dataB;
    
    SetupInputData(dataA, dataB);
    ExpectOutputData(expectedResult);
    
    model->step();
}

// Test with receive failure
TEST_F(oMessageModelTest, StepWithReceiveFailure) {
    // Setup receive to fail
    EXPECT_CALL(*mockRecvData, RecvData(_, sizeof(InputDataInterface), _))
        .WillOnce(SetArgPointee<2>(0)); // Set status to 0 (failure)
    
    // Still expect send to be called (model continues execution)
    EXPECT_CALL(*mockSendData, SendData(_, sizeof(OutputDataInterface), _))
        .Times(1);
    
    model->step();
}

// Performance test (basic timing)
TEST_F(oMessageModelTest, StepPerformanceTest) {
    SetupInputData(6.0, 4.0);
    ExpectOutputData(10.0);
    
    auto start = std::chrono::high_resolution_clock::now();
    model->step();
    auto end = std::chrono::high_resolution_clock::now();
    
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    
    // Expect step to complete in reasonable time (adjust threshold as needed)
    EXPECT_LT(duration.count(), 1000); // Less than 1ms
}