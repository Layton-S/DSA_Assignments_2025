import ballerina/io;

// Admin-specific functions for the car rental system

public function handleAdminOperations(CarRentalServiceClient client, string choice) returns error? {
    match choice {
        "1" => { check addCar(client); }
        "2" => { check updateCar(client); }
        "3" => { check removeCar(client); }
        "4" => { check listAvailableCars(client); }
        "5" => { check searchCar(client); }
        "6" => { check listReservations(client); }
        _ => { io:println("Invalid choice!"); }
    }
}

public function addCar(CarRentalServiceClient client) returns error? {
    io:println("\n=== Add New Car ===");
    io:print("Enter plate number: ");
    string plate = io:readln().trim();
    io:print("Enter make: ");
    string make = io:readln().trim();
    io:print("Enter model: ");
    string model = io:readln().trim();
    io:print("Enter year: ");
    string yearStr = io:readln().trim();
    int year = check int:fromString(yearStr);
    io:print("Enter daily price: ");
    string priceStr = io:readln().trim();
    float price = check float:fromString(priceStr);
    io:print("Enter mileage: ");
    string mileageStr = io:readln().trim();
    int mileage = check int:fromString(mileageStr);
    
    Car car = {
        plate: plate,
        make: make,
        model: model,
        year: year,
        daily_price: price,
        mileage: mileage,
        status: "AVAILABLE"
    };
    
    AddCarResponse result = check client->AddCar({car: car});
    io:println("Response: " + result.message);
}

public function updateCar(CarRentalServiceClient client) returns error? {
    io:println("\n=== Update Car ===");
    io:print("Enter plate number to update: ");
    string plate = io:readln().trim();
    
    Car car = {plate: "", make: "", model: "", year: 0, daily_price: 0.0, mileage: 0, status: ""};
    
    io:print("Enter new make (or press Enter to skip): ");
    string make = io:readln().trim();
    if make != "" { car.make = make; }
    
    io:print("Enter new model (or press Enter to skip): ");
    string model = io:readln().trim();
    if model != "" { car.model = model; }
    
    io:print("Enter new year (or press Enter to skip): ");
    string yearStr = io:readln().trim();
    if yearStr != "" {
        int year = check int:fromString(yearStr);
        car.year = year;
    }
    
    io:print("Enter new daily price (or press Enter to skip): ");
    string priceStr = io:readln().trim();
    if priceStr != "" {
        float price = check float:fromString(priceStr);
        car.daily_price = price;
    }
    
    io:print("Enter new status AVAILABLE/UNAVAILABLE (or press Enter to skip): ");
    string status = io:readln().trim();
    if status != "" { car.status = status; }
    
    UpdateCarResponse result = check client->UpdateCar({plate: plate, car: car});
    io:println("Response: " + result.message);
}

public function removeCar(CarRentalServiceClient client) returns error? {
    io:println("\n=== Remove Car ===");
    io:print("Enter plate number to remove: ");
    string plate = io:readln().trim();
    
    CarsListResponse result = check client->RemoveCar({plate: plate});
    io:println("Response: " + result.message);
    io:println("Remaining cars:");
    foreach Car c in result.cars {
        io:println("  " + c.plate + " - " + c.make + " " + c.model + " (" + c.year.toString() + ") - $" + c.daily_price.toString() + "/day");
    }
}

public function listReservations(CarRentalServiceClient client) returns error? {
    io:println("\n=== All Reservations ===");
    
    ListReservationsResponse result = check client->ListReservations({});
    io:println("All Reservations:");
    
    if result.reservations.length() == 0 {
        io:println("No reservations found.");
    } else {
        foreach Reservation r in result.reservations {
            io:println("  User: " + r.username);
            io:println("  Car: " + r.plate);
            io:println("  Dates: " + r.start_date + " to " + r.end_date);
            io:println("  Days: " + r.days.toString());
            io:println("  Total Price: $" + r.total_price.toString());
            io:println("  ---");
        }
    }
}