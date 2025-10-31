#include <gtest/gtest.h>
#include "mock_interfaces.h"
#include "../oMessage_Model_ert_rtw/oMessage_Model.h"

using namespace ComponentNamespace;

// Parameterized test for addition cases
class AdditionTest : public ::testing::TestWithParam<TestDataHelper::TestCase> {
protected:
    void SetUp() override {
        mockRecvData = std::make_unique<MockRecvDataInterface>();
        mockSendData = std::make_unique<MockSendDataInterface>();
        model = std::make_unique<oMessage_Model>(*mockRecvData, *mockSendData);
    }

    std::unique_ptr<MockRecvDataInterface> mockRecvData;
    std::unique_ptr<MockSendDataInterface> mockSendData;
    std::unique_ptr<oMessage_Model> model;
};

TEST_P(AdditionTest, DataDrivenAdditionTests) {
    auto testCase = GetParam();
    
    mockRecvData->SetupSuccessfulReceive(testCase.inputA, testCase.inputB);
    mockSendData->ExpectSuccessfulSend(testCase.expectedOutput);
    
    model->step();
}

INSTANTIATE_TEST_SUITE_P(
    AdditionTestCases,
    AdditionTest,
    ::testing::ValuesIn(TestDataHelper::AdditionTestCases),
    [](const ::testing::TestParamInfo<TestDataHelper::TestCase>& info) {
        return std::string(info.param.description);
    }
);

// Parameterized test for multiplication cases
class MultiplicationTest : public ::testing::TestWithParam<TestDataHelper::TestCase> {
protected:
    void SetUp() override {
        mockRecvData = std::make_unique<MockRecvDataInterface>();
        mockSendData = std::make_unique<MockSendDataInterface>();
        model = std::make_unique<oMessage_Model>(*mockRecvData, *mockSendData);
    }

    std::unique_ptr<MockRecvDataInterface> mockRecvData;
    std::unique_ptr<MockSendDataInterface> mockSendData;
    std::unique_ptr<oMessage_Model> model;
};

TEST_P(MultiplicationTest, DataDrivenMultiplicationTests) {
    auto testCase = GetParam();
    
    mockRecvData->SetupSuccessfulReceive(testCase.inputA, testCase.inputB);
    mockSendData->ExpectSuccessfulSend(testCase.expectedOutput);
    
    model->step();
}

INSTANTIATE_TEST_SUITE_P(
    MultiplicationTestCases,
    MultiplicationTest,
    ::testing::ValuesIn(TestDataHelper::MultiplicationTestCases),
    [](const ::testing::TestParamInfo<TestDataHelper::TestCase>& info) {
        return std::string(info.param.description);
    }
);

// Parameterized test for boundary cases
class BoundaryTest : public ::testing::TestWithParam<TestDataHelper::TestCase> {
protected:
    void SetUp() override {
        mockRecvData = std::make_unique<MockRecvDataInterface>();
        mockSendData = std::make_unique<MockSendDataInterface>();
        model = std::make_unique<oMessage_Model>(*mockRecvData, *mockSendData);
    }

    std::unique_ptr<MockRecvDataInterface> mockRecvData;
    std::unique_ptr<MockSendDataInterface> mockSendData;
    std::unique_ptr<oMessage_Model> model;
};

TEST_P(BoundaryTest, DataDrivenBoundaryTests) {
    auto testCase = GetParam();
    
    mockRecvData->SetupSuccessfulReceive(testCase.inputA, testCase.inputB);
    mockSendData->ExpectSuccessfulSend(testCase.expectedOutput);
    
    model->step();
}

INSTANTIATE_TEST_SUITE_P(
    BoundaryTestCases,
    BoundaryTest,
    ::testing::ValuesIn(TestDataHelper::BoundaryTestCases),
    [](const ::testing::TestParamInfo<TestDataHelper::TestCase>& info) {
        return std::string(info.param.description);
    }
);