import ballerina/grpc;
import ballerina/io;

// ------------------------- gRPC Client -------------------------
public client class CarRentalServiceClient {
    private grpc:Client grpcClient;

    public function init(string url = "http://localhost:9090") returns error? {
        self.grpcClient = check new(url);
    }

    remote function AddCar(json car) returns json|error {
        var result = self.grpcClient->executeSimpleRPC("CarRentalService/AddCar", car);
        if result is [anydata, map<string|string[]>] {
            return <json>result[0];
        } else if result is grpc:Error {
            return result;
        }
        return error("Unexpected response type");
    }

    remote function ListAvailableCars(json request) returns json[]|error {
        var result = self.grpcClient->executeServerStreaming("CarRentalService/ListAvailableCars", request);
        if result is [stream<anydata, grpc:Error?>, map<string|string[]>] {
            stream<anydata, grpc:Error?> dataStream = result[0];
            json[] cars = [];

            while true {
                var next = check dataStream.next();
                if next is () {
                    break;
                }
                cars.push(<json>next);
            }
            return cars;
        } else if result is grpc:Error {
            return result;
        }
        return error("Unexpected response type");
    }
}

// ------------------------- Global Variables -------------------------
string currentUserId = "";
string currentUserRole = "CUSTOMER";
CarRentalServiceClient carRentalClient;

// ------------------------- Main -------------------------
public function main() returns error? {
    io:println("=== Car Rental System Client ===");

    var clientResult = new CarRentalServiceClient();
    if clientResult is CarRentalServiceClient {
        carRentalClient = clientResult;
    } else {
        io:println("Failed to connect to server: " + clientResult.message());
        return clientResult;
    }

    io:println("Connected to Car Rental Server successfully!\n");

    while true {
        if currentUserId == "" {
            loginUser();
        } else {
            showMainMenu();
        }
    }
}

// ------------------------- Login -------------------------
function loginUser() {
    io:println("=== Login ===");
    io:print("Enter User ID (admin1, customer1, customer2): ");
    string? userInput = io:readln();

    if userInput is string {
        string userId = userInput.trim();
        if userId.length() > 0 {
            currentUserId = userId;
            if userId.startsWith("admin") {
                currentUserRole = "ADMIN";
                io:println("Logged in as Admin: " + userId);
            } else {
                currentUserRole = "CUSTOMER";
                io:println("Logged in as Customer: " + userId);
            }
            io:println("");
        }
    }
}

// ------------------------- Menu -------------------------
function showMainMenu() {
    io:println("=== Main Menu ===");
    if currentUserRole == "ADMIN" {
        showAdminMenu();
    } else {
        showCustomerMenu();
    }
}

function showAdminMenu() {
    io:println("Admin Operations:");
    io:println("1. Add Car");
    io:println("2. View Available Cars");
    io:println("0. Logout");
    io:print("Select option: ");

    string? input = io:readln();
    if input is string {
        match input.trim() {
    "1" => {
        addCar();
    }
    "2" => {
        viewAvailableCars();
    }
    "0" => {
        logout();
    }
    _ => {
        io:println("Invalid option. Please try again.\n");
    }
}

}
}

function showCustomerMenu() {
    io:println("Customer Operations:");
    io:println("1. View Available Cars");
    io:println("0. Logout");
    io:print("Select option: ");

    string? input = io:readln();
    if input is string {
        match input.trim() {
            "1" => {
                viewAvailableCars();
            }
            "0" => {
                logout();
            }
            _ => {
                io:println("Invalid option. Please try again.\n");
            }
        }
    }
}


// ------------------------- Admin Operations -------------------------
function addCar() {
    io:println("\n=== Add New Car ===");
    io:print("Enter plate number: ");
    string? plate = io:readln();
    if plate is () || plate.trim().length() == 0 {
        io:println("Invalid plate number.\n");
        return;
    }

    io:print("Enter make: ");
    string? make = io:readln();
    if make is () || make.trim().length() == 0 {
        io:println("Invalid make.\n");
        return;
    }

    io:print("Enter model: ");
    string? model = io:readln();
    if model is () || model.trim().length() == 0 {
        io:println("Invalid model.\n");
        return;
    }

    io:print("Enter year: ");
    string? yearStr = io:readln();
    int|error year = int:fromString(yearStr ?: "0");
    if year is error || year <= 1900 {
        io:println("Invalid year.\n");
        return;
    }

    io:print("Enter daily price: ");
    string? priceStr = io:readln();
    float|error dailyPrice = float:fromString(priceStr ?: "0");
    if dailyPrice is error || dailyPrice <= 0.0 {
        io:println("Invalid daily price.\n");
        return;
    }

    io:print("Enter mileage: ");
    string? mileageStr = io:readln();
    int|error mileage = int:fromString(mileageStr ?: "0");
    if mileage is error || mileage < 0 {
        io:println("Invalid mileage.\n");
        return;
    }

    json newCar = {
        "plate": plate.trim(),
        "make": make.trim(),
        "model": model.trim(),
        "year": year,
        "dailyPrice": dailyPrice,
        "mileage": mileage
    };

    json|error result = carRentalClient->AddCar(newCar);
    if result is json {
        map<json> resMap = <map<json>>result;
        boolean success = resMap["success"] is boolean ? <boolean>resMap["success"] : false;
        if success {
            io:println("Car added successfully!\n");
        } else {
            io:println("Failed to add car.\n");
        }
    } else {
        io:println("Error adding car: " + result.message());
    }
}

// ------------------------- View Cars -------------------------
function viewAvailableCars() {
    io:println("\n=== Available Cars ===");
    json request = {};
    json[]|error cars = carRentalClient->ListAvailableCars(request);

    if cars is json[] {
        if cars.length() == 0 {
            io:println("No cars available.\n");
            return;
        }

        foreach var car in cars {
            if car is map<json> {
                map<json> c = car;

                // Plate
                string plate = "";
                if c["plate"] is string {
                    plate = <string>c["plate"];
                }

                // Make
                string make = "";
                if c["make"] is string {
                    make = <string>c["make"];
                }

                // Model
                string model = "";
                if c["model"] is string {
                    model = <string>c["model"];
                }

                // Year
                string year = "";
                if c["year"] is int {
                    year = string(<int>c["year"]);
                } else if c["year"] is float {
                    year = string(<float>c["year"]);
                }

                // Daily Price
                string price = "";
                if c["dailyPrice"] is int {
                    price = string(<int>c["dailyPrice"]);
                } else if c["dailyPrice"] is float {
                    price = string(<float>c["dailyPrice"]);
                }

                // Mileage
                string mileage = "";
                if c["mileage"] is int {
                    mileage = string(<int>c["mileage"]);
                } else if c["mileage"] is float {
                    mileage = string(<float>c["mileage"]);
                }

                // Print car details
                io:println("Plate: " + plate);
                io:println("Make: " + make);
                io:println("Model: " + model);
                io:println("Year: " + year);
                io:println("Price: " + price);
                io:println("Mileage: " + mileage);
                io:println("---------------------------");
            }
        }
    } else {
        io:println("Error fetching cars: " + cars.message());
    }
}



// ------------------------- Logout -------------------------
function logout() {
    currentUserId = "";
    currentUserRole = "CUSTOMER";
    io:println("\nLogged out successfully.\n");
}
