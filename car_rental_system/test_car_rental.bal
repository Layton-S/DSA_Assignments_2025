
// import ballerina/test;
// import ballerina/io;

// // Test basic functionality without requiring server
// @test:Config {}
// function testBasicTypes() returns error? {
//     Car testCar = {
//         plate: "TEST001",
//         make: "Tesla",
//         model: "Model 3",
//         year: 2023,
//         daily_price: 80.0,
//         mileage: 5000,
//         status: AVAILABLE
//     };
    
//     test:assertEquals(testCar.plate, "TEST001");
//     test:assertEquals(testCar.make, "Tesla");
//     io:println("✓ Basic types test passed");
// }

// @test:Config {}
// function testUserTypes() returns error? {
//     User testUser = {
//         user_id: "user1",
//         name: "Test User",
//         email: "test@email.com",
//         role: CUSTOMER,
//         password: "pass123"
//     };
    
//     test:assertEquals(testUser.user_id, "user1");
//     test:assertEquals(testUser.role, CUSTOMER);
//     io:println("✓ User types test passed");
// }