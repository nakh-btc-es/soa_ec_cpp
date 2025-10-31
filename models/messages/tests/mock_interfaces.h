#ifndef MOCK_INTERFACES_H
#define MOCK_INTERFACES_H

#include <gmock/gmock.h>
#include "../oMessage_Model_ert_rtw/oMessage_Model_types.h"

// Mock class for RecvData_InputDataInterfaceT
class MockRecvDataInterface : public RecvData_InputDataInterfaceT {
public:
    MOCK_METHOD(void, RecvData, (InputDataInterface* data, int32_T length, int32_T* status), (override));
    
    // Helper method to easily set up successful receive with specific data
    void SetupSuccessfulReceive(double dataA, double dataB) {
        InputDataInterface inputData;
        inputData.DataA = dataA;
        inputData.DataB = dataB;
        
        EXPECT_CALL(*this, RecvData(::testing::_, sizeof(InputDataInterface), ::testing::_))
            .WillOnce(::testing::DoAll(
                ::testing::SetArgPointee<0>(inputData),
                ::testing::SetArgPointee<2>(1)  // Success status
            ));
    }
    
    // Helper method to set up failed receive
    void SetupFailedReceive() {
        EXPECT_CALL(*this, RecvData(::testing::_, sizeof(InputDataInterface), ::testing::_))
            .WillOnce(::testing::SetArgPointee<2>(0));  // Failure status
    }
};

// Mock class for SendData_OutputDataInterfaceT
class MockSendDataInterface : public SendData_OutputDataInterfaceT {
public:
    MOCK_METHOD(void, SendData, (const OutputDataInterface* data, int32_T length, int32_T* status), (override));
    
    // Helper method to verify output data and set success status
    void ExpectSuccessfulSend(double expectedDataC) {
        EXPECT_CALL(*this, SendData(::testing::_, sizeof(OutputDataInterface), ::testing::_))
            .WillOnce([expectedDataC](const OutputDataInterface* data, int32_T length, int32_T* status) {
                EXPECT_DOUBLE_EQ(data->DataC, expectedDataC);
                *status = 1;  // Success status
            });
    }
    
    // Helper method to simulate failed send
    void SetupFailedSend() {
        EXPECT_CALL(*this, SendData(::testing::_, sizeof(OutputDataInterface), ::testing::_))
            .WillOnce(::testing::SetArgPointee<2>(0));  // Failure status
    }
    
    // Helper method to capture output data for later verification
    void CaptureOutputData(OutputDataInterface& capturedData) {
        EXPECT_CALL(*this, SendData(::testing::_, sizeof(OutputDataInterface), ::testing::_))
            .WillOnce([&capturedData](const OutputDataInterface* data, int32_T length, int32_T* status) {
                capturedData = *data;
                *status = 1;
            });
    }
};

// Test data helper class
class TestDataHelper {
public:
    // Creates input data with specified values
    static InputDataInterface CreateInputData(double dataA, double dataB) {
        InputDataInterface data;
        data.DataA = dataA;
        data.DataB = dataB;
        return data;
    }
    
    // Creates output data with specified value
    static OutputDataInterface CreateOutputData(double dataC) {
        OutputDataInterface data;
        data.DataC = dataC;
        return data;
    }
    
    // Test data sets for common scenarios
    struct TestCase {
        double inputA;
        double inputB;
        double expectedOutput;
        const char* description;
    };
    
    // Predefined test cases
    static const TestCase AdditionTestCases[];
    static const TestCase MultiplicationTestCases[];
    static const TestCase EdgeCases[];
    static const TestCase BoundaryTestCases[];
    
    static size_t GetAdditionTestCaseCount();
    static size_t GetMultiplicationTestCaseCount();
    static size_t GetEdgeCaseCount();
    static size_t GetBoundaryTestCaseCount();
};

// Implementation of test cases
inline const TestDataHelper::TestCase TestDataHelper::AdditionTestCases[] = {
    {6.0, 4.0, 10.0, "Basic addition case"},
    {10.5, 2.5, 13.0, "Decimal addition"},
    {100.0, 50.0, 150.0, "Large number addition"},
    {5.1, 0.0, 5.1, "Addition with zero"},
    {7.5, -2.5, 5.0, "Addition with negative"}
};

inline const TestDataHelper::TestCase TestDataHelper::MultiplicationTestCases[] = {
    {4.0, 3.0, 12.0, "Basic multiplication case"},
    {2.5, 4.0, 10.0, "Decimal multiplication"},
    {0.0, 5.0, 0.0, "Multiplication with zero"},
    {-2.0, 3.0, -6.0, "Multiplication with negative"},
    {1.5, 2.0, 3.0, "Small decimal multiplication"}
};

inline const TestDataHelper::TestCase TestDataHelper::EdgeCases[] = {
    {0.0, 0.0, 0.0, "Both inputs zero"},
    {-5.0, -3.0, 15.0, "Both inputs negative"},
    {1e-10, 1e10, 1.0, "Very small and very large"},
    {5.0, 0.0, 0.0, "Exactly 5.0 with zero"}
};

inline const TestDataHelper::TestCase TestDataHelper::BoundaryTestCases[] = {
    {5.0, 3.0, 15.0, "Exactly 5.0 (multiplication)"},
    {5.000001, 3.0, 8.000001, "Just above 5.0 (addition)"},
    {4.999999, 3.0, 14.999997, "Just below 5.0 (multiplication)"}
};

inline size_t TestDataHelper::GetAdditionTestCaseCount() {
    return sizeof(AdditionTestCases) / sizeof(AdditionTestCases[0]);
}

inline size_t TestDataHelper::GetMultiplicationTestCaseCount() {
    return sizeof(MultiplicationTestCases) / sizeof(MultiplicationTestCases[0]);
}

inline size_t TestDataHelper::GetEdgeCaseCount() {
    return sizeof(EdgeCases) / sizeof(EdgeCases[0]);
}

inline size_t TestDataHelper::GetBoundaryTestCaseCount() {
    return sizeof(BoundaryTestCases) / sizeof(BoundaryTestCases[0]);
}

#endif // MOCK_INTERFACES_H