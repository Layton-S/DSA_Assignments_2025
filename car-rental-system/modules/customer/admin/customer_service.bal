import ballerina/io;
import ballerina/grpc;

// Customer-specific functions for the car rental system

public function handleCustomerOperations(CarRentalServiceClient client, string choice, string username) returns error? {
    match choice {
        "1" => { check listAvailableCars(client); }
        "2" => { check searchCar(client); }
        "3" => { check addToCart(client, username); }
        "4" => { check placeReservation(client, username); }
        _ => { io:println("Invalid choice!"); }
    }
}

public function listAvailableCars(CarRentalServiceClient client) returns error? {
    io:println("\n=== Available Cars ===");
    io:print("Enter filter (optional, press Enter to skip): ");
    string filter = io:readln().trim();
    
    stream<Car, grpc:Error?> carStream = check client->ListAvailableCars({filter: filter});
    
    io:println("Available cars:");
    error? e = carStream.forEach(function(Car c) {
        io:println("  " + c.plate + " - " + c.make + " " + c.model + " (" + c.year.toString() + ") - $" + c.daily_price.toString() + "/day - " + c.mileage.toString() + " miles");
    });
    
    if e is error {
        io:println("Error listing cars: " + e.message());
        return e;
    }
}

public function searchCar(CarRentalServiceClient client) returns error? {
    io:println("\n=== Search Car ===");
    io:print("Enter plate number: ");
    string plate = io:readln().trim();
    
    SearchCarResponse result = check client->SearchCar({plate: plate});
    io:println("Response: " + result.message);
    
    if result.found {
        Car c = result.car;
        io:println("Car Details:");
        io:println("  Plate: " + c.plate);
        io:println("  Make: " + c.make);
        io:println("  Model: " + c.model);
        io:println("  Year: " + c.year.toString());
        io:println("  Daily Price: $" + c.daily_price.toString());
        io:println("  Mileage: " + c.mileage.toString() + " miles");
        io:println("  Status: " + c.status);
    }
}

public function addToCart(CarRentalServiceClient client, string username) returns error? {
    io:println("\n=== Add Car to Cart ===");
    io:print("Enter plate number: ");
    string plate = io:readln().trim();
    io:print("Enter start date (YYYY-MM-DD): ");
    string startDate = io:readln().trim();
    io:print("Enter end date (YYYY-MM-DD): ");
    string endDate = io:readln().trim();
    
    AddToCartResponse result = check client->AddToCart({
        username: username,
        plate: plate,
        start_date: startDate,
        end_date: endDate
    });
    
    io:println("Response: " + result.message);
}

public function placeReservation(CarRentalServiceClient client, string username) returns error? {
    io:println("\n=== Place Reservation ===");
    
    PlaceReservationResponse result = check client->PlaceReservation({username: username});
    io:println("Response: " + result.message);
    
    if result.ok {
        io:println("Confirmed Reservations:");
        foreach Reservation r in result.reservations {
            io:println("  Car: " + r.plate);
            io:println("  Dates: " + r.start_date + " to " + r.end_date);
            io:println("  Days: " + r.days.toString());
            io:println("  Total Price: $" + r.total_price.toString());
            io:println("  ---");
        }
    }
}