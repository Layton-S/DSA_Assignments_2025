import ballerina/grpc;
import ballerina/log;
import ballerina/time;

// gRPC listener on port 9090
listener grpc:Listener carRentalListener = new(9090);

// In-memory data storage
map<Car> cars = {};
map<User> users = {};
map<CartItem[]> userCarts = {};
Reservation[] reservations = [];

// Basic data types
type Car record {
    string plate;
    string make;
    string model;
    int year;
    float daily_price;
    int mileage;
    string status; // "AVAILABLE" or "UNAVAILABLE"
};

type User record {
    string username;
    string role; // "ADMIN" or "CUSTOMER"
};

type CartItem record {
    string plate;
    string start_date; // Format: YYYY-MM-DD
    string end_date;   // Format: YYYY-MM-DD
};

type Reservation record {
    string username;
    string plate;
    string start_date;
    string end_date;
    int days;
    float total_price;
};

// Helper function to calculate days between dates
function calculateDays(string startDate, string endDate) returns int|error {
    string startDateTime = startDate + "T00:00:00Z";
    string endDateTime = endDate + "T00:00:00Z";
    
    time:Utc startUtc = check time:utcFromString(startDateTime);
    time:Utc endUtc = check time:utcFromString(endDateTime);
    
    decimal diffSeconds = time:utcDiffSeconds(endUtc, startUtc);
    
    if diffSeconds < 0.0d {
        return error("End date must be after start date");
    }
    
    int days = <int>(diffSeconds / 86400.0d) + 1; // +1 for inclusive counting
    return days;
}

// Helper function to check date overlap
function hasDateOverlap(string start1, string end1, string start2, string end2) returns boolean {
    // Simple string comparison works for YYYY-MM-DD format
    return !(end1 < start2 || end2 < start1);
}

// Request type for add_to_cart
type AddToCartRequest record {
    string username;
    string plate;
    string startDate;
    string endDate;
};

// Request type for update_car
type UpdateCarRequest record {
    string plate;
    Car updates;
};

// Main gRPC service
service "CarRentalService" on carRentalListener {

    // Admin adds a car to the system
    remote function add_car(Car car) returns string|error {
        if car.plate == "" {
            return error("Car plate is required");
        }
        
        if cars.hasKey(car.plate) {
            return error("Car with plate " + car.plate + " already exists");
        }
        
        // Set default status if not provided
        if car.status == "" {
            car.status = "AVAILABLE";
        }
        
        cars[car.plate] = car;
        log:printInfo("Car added: " + car.plate);
        return "Car " + car.plate + " added successfully";
    }

    // Admin updates car details
    remote function update_car(UpdateCarRequest req) returns string|error {
        string plate = req.plate;
        Car updates = req.updates;

        if !cars.hasKey(plate) {
            return error("Car with plate " + plate + " not found");
        }
        
        Car existingCar = cars.get(plate);
        
        // Update only non-empty/non-zero fields
        if updates.make != "" {
            existingCar.make = updates.make;
        }
        if updates.model != "" {
            existingCar.model = updates.model;
        }
        if updates.year != 0 {
            existingCar.year = updates.year;
        }
        if updates.daily_price != 0.0 {
            existingCar.daily_price = updates.daily_price;
        }
        if updates.mileage != 0 {
            existingCar.mileage = updates.mileage;
        }
        if updates.status != "" {
            existingCar.status = updates.status;
        }
        
        cars[plate] = existingCar;
        log:printInfo("Car updated: " + plate);
        return "Car " + plate + " updated successfully";
    }

    // Admin removes a car and returns updated list
    remote function remove_car(string plate) returns Car[]|error {
        if cars.hasKey(plate) {
            _ = cars.remove(plate);
            log:printInfo("Car removed: " + plate);
        }
        
        // Return all remaining cars
        Car[] remainingCars = [];
        foreach Car car in cars {
            remainingCars.push(car);
        }
        
        return remainingCars;
    }

    // Customer lists available cars (with optional filter)
    remote function list_available_cars(string filter) returns Car[]|error {
        Car[] availableCars = [];
        
        foreach Car car in cars {
            if car.status == "AVAILABLE" {
                // Apply filter if provided
                if filter == "" {
                    availableCars.push(car);
                } else {
                    string filterLower = filter.toLowerAscii();
                    if car.make.toLowerAscii().includes(filterLower) ||
                       car.model.toLowerAscii().includes(filterLower) ||
                       car.plate.toLowerAscii().includes(filterLower) ||
                       car.year.toString().includes(filter) {
                        availableCars.push(car);
                    }
                }
            }
        }
        return availableCars;
    }

    // Customer searches for a specific car by plate
    remote function search_car(string plate) returns Car|error {
        if !cars.hasKey(plate) {
            return error("Car with plate " + plate + " not found");
        }
        
        Car car = cars.get(plate);
        return car;
    }

    remote function add_to_cart(AddToCartRequest req) returns string|error {
    type AddToCartRequest record {
        string username;
        string plate;
        string startDate;
        string endDate;
    }

    remote function add_to_cart(AddToCartRequest req) returns string|error {
        string username = req.username;
        string plate = req.plate;
        string startDate = req.startDate;
        string endDate = req.endDate;

        // Check if user exists
        if !users.hasKey(username) {
            return error("User " + username + " not found");
        }
        
        // Check if car exists
        if !cars.hasKey(plate) {
            return error("Car with plate " + plate + " not found");
        }
        
        // Validate dates
        int|error daysResult = calculateDays(startDate, endDate);
        if daysResult is error {
            return error("Invalid dates: " + daysResult.message());
        }
        
        // Initialize cart if doesn't exist
        if !userCarts.hasKey(username) {
            userCarts[username] = [];
        }
        
        // Add to cart
        CartItem[] cart = userCarts.get(username);
        CartItem newItem = {
            plate: plate,
            start_date: startDate,
            end_date: endDate
        };
        cart.push(newItem);
        userCarts[username] = cart;
        
        log:printInfo("Added to cart - User: " + username + ", Car: " + plate + ", Dates: " + startDate + " to " + endDate);
        return "Car " + plate + " added to cart for " + startDate + " to " + endDate;
    }
            end_date: endDate
        };
        cart.push(newItem);
        userCarts[username] = cart;
        
        log:printInfo("Added to cart - User: " + username + ", Car: " + plate + ", Dates: " + startDate + " to " + endDate);
        return "Car " + plate + " added to cart for " + startDate + " to " + endDate;
    }

    // Customer places reservation from their cart
    remote function place_reservation(string username) returns Reservation[]|error {
        // Check if user has a cart
        if !userCarts.hasKey(username) {
            return error("No items in cart for user " + username);
        }
        
        CartItem[] cartItems = userCarts.get(username);
        if cartItems.length() == 0 {
            return error("Cart is empty for user " + username);
        }
        
        Reservation[] newReservations = [];
        
        foreach CartItem item in cartItems {
            string plate = item.plate;
            string startDate = item.start_date;
            string endDate = item.end_date;
            
            // Check if car still exists and is available
            if !cars.hasKey(plate) {
                log:printWarn("Car " + plate + " no longer exists, skipping");
                continue;
            }
            
            Car car = cars.get(plate);
            if car.status != "AVAILABLE" {
                log:printWarn("Car " + plate + " no longer available, skipping");
                continue;
            }
            
            // Check for date conflicts with existing reservations
            boolean hasConflict = false;
            foreach Reservation existingReservation in reservations {
                if existingReservation.plate == plate {
                    if hasDateOverlap(startDate, endDate, existingReservation.start_date, existingReservation.end_date) {
                        hasConflict = true;
                        log:printWarn("Date conflict for car " + plate + ", skipping");
                        break;
                    }
                }
            }
            
            if hasConflict {
                continue;
            }
            
            // Calculate days and total price
            int|error daysResult = calculateDays(startDate, endDate);
            if daysResult is error {
                log:printWarn("Invalid dates for car " + plate + ", skipping");
                continue;
            }
            int days = daysResult;
            float totalPrice = <float>days * car.daily_price;
            
            // Create reservation
            Reservation reservation = {
                username: username,
                plate: plate,
                start_date: startDate,
                end_date: endDate,
                days: days,
                total_price: totalPrice
            };
            
            // Add to reservations and mark car as unavailable
            reservations.push(reservation);
            newReservations.push(reservation);
            car.status = "UNAVAILABLE";
            cars[plate] = car;
            
            log:printInfo("Reservation created - User: " + username + ", Car: " + plate + ", Total: $" + totalPrice.toString());
        }
        
        // Clear the cart
        userCarts[username] = [];
        
        if newReservations.length() == 0 {
            return error("No reservations could be confirmed");
        }
        
        return newReservations;
    }

    // List all reservations (for admin)
    remote function list_reservations() returns Reservation[]|error {
        return reservations;
    }
}

public function main() returns error? {
    log:printInfo("Car Rental Server started on port 9090");
    log:printInfo("Ready to accept gRPC connections...");
}