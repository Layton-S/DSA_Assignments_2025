import ballerina/grpc;
import ballerina/io;
import car_rental_system.customer.admin;

// Import generated types from the proto
// Note: Adjust these imports based on your generated files structure

// Data types - these should match the service definitions
public type Car record {
    string plate;
    string make;
    string model;
    int year;
    float daily_price;
    int mileage;
    string status;
};

public type User record {
    string username;
    string role;
};

public type Reservation record {
    string username;
    string plate;
    string start_date;
    string end_date;
    int days;
    float total_price;
};

// Request/Response types
public type AddCarRequest record {
    Car car;
};

public type AddCarResponse record {
    string plate;
    string message;
};

public type CreateUsersResponse record {
    int created;
    string message;
};

public type UpdateCarRequest record {
    string plate;
    Car car;
};

public type UpdateCarResponse record {
    boolean ok;
    string message;
};

public type RemoveCarRequest record {
    string plate;
};

public type CarsListResponse record {
    Car[] cars;
    string message;
};

public type AvailableCarsRequest record {
    string filter;
};

public type SearchCarRequest record {
    string plate;
};

public type SearchCarResponse record {
    boolean found;
    Car car;
    string message;
};

public type AddToCartRequest record {
    string username;
    string plate;
    string start_date;
    string end_date;
};

public type AddToCartResponse record {
    boolean ok;
    string message;
};

public type PlaceReservationRequest record {
    string username;
};

public type PlaceReservationResponse record {
    boolean ok;
    Reservation[] reservations;
    string message;
};

public type ListReservationsRequest record {
};

public type ListReservationsResponse record {
    Reservation[] reservations;
    string message;
};

// Mock gRPC client for now - replace with actual generated client
public client class CarRentalServiceClient {
    private grpc:Client grpcClient;
    
    public function init(string url) returns error? {
        self.grpcClient = check new(url);
    }
    
    remote function AddCar(AddCarRequest req) returns AddCarResponse|error {
        return check self.grpcClient->execute("CarRentalService/AddCar", req);
    }
    
    remote function CreateUsers(stream<User, error?> users) returns CreateUsersResponse|error {
        return check self.grpcClient->execute("CarRentalService/CreateUsers", users);
    }
    
    remote function UpdateCar(UpdateCarRequest req) returns UpdateCarResponse|error {
        return check self.grpcClient->execute("CarRentalService/UpdateCar", req);
    }
    
    remote function RemoveCar(RemoveCarRequest req) returns CarsListResponse|error {
        return check self.grpcClient->execute("CarRentalService/RemoveCar", req);
    }
    
    remote function ListAvailableCars(AvailableCarsRequest req) returns stream<Car, grpc:Error?>|error {
        return check self.grpcClient->execute("CarRentalService/ListAvailableCars", req);
    }
    
    remote function SearchCar(SearchCarRequest req) returns SearchCarResponse|error {
        return check self.grpcClient->execute("CarRentalService/SearchCar", req);
    }
    
    remote function AddToCart(AddToCartRequest req) returns AddToCartResponse|error {
        return check self.grpcClient->execute("CarRentalService/AddToCart", req);
    }
    
    remote function PlaceReservation(PlaceReservationRequest req) returns PlaceReservationResponse|error {
        return check self.grpcClient->execute("CarRentalService/PlaceReservation", req);
    }
    
    remote function ListReservations(ListReservationsRequest req) returns ListReservationsResponse|error {
        return check self.grpcClient->execute("CarRentalService/ListReservations", req);
    }
}

public function main() returns error? {
    // Create gRPC client
    CarRentalServiceClient carClient = check new("http://localhost:9090");
    
    string currentUser = "";
    string currentRole = "";
    
    io:println("Welcome to Car Rental System!");
    io:println("================================");
    
    // First, create a user
    io:println("First, let's create a user account:");
    io:print("Enter username: ");
    currentUser = io:readln().trim();
    io:print("Enter role (ADMIN/CUSTOMER): ");
    currentRole = io:readln().trim().toUpperAscii();
    
    // Create user
    User[] users = [{username: currentUser, role: currentRole}];
    stream<User, error?> userStream = users.toStream();
    CreateUsersResponse createResult = check carClient->CreateUsers(userStream);
    io:println("User created successfully! " + createResult.message);
    
    while true {
        io:println("\n=== Car Rental System Menu ===");
        
        if currentRole == "ADMIN" {
            io:println("1. Add Car");
            io:println("2. Update Car");
            io:println("3. Remove Car");
            io:println("4. List Available Cars");
            io:println("5. Search Car");
            io:println("6. List All Reservations");
        } else {
            io:println("1. List Available Cars");
            io:println("2. Search Car");
            io:println("3. Add Car to Cart");
            io:println("4. Place Reservation");
        }
        io:println("0. Exit");
        
        io:print("Enter your choice: ");
        string choice = io:readln().trim();
        
        if choice == "0" {
            io:println("Thank you for using Car Rental System!");
            break;
        }
        
        if currentRole == "ADMIN" {
            check admin:handleAdminOperations(carClient, choice);
        } else {
            check admin:handleCustomerOperations(carClient, choice, currentUser);
        }
    }
}