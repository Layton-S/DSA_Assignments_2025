import ballerina/grpc;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// Type definitions
public enum CarStatus {
    AVAILABLE,
    UNAVAILABLE,
    RENTED
}

public enum UserRole {
    CUSTOMER,
    ADMIN
}

public type Car record {|
    string plate;
    string make;
    string model;
    int year;
    float daily_price;
    int mileage;
    CarStatus status;
|};

public type User record {|
    string user_id;
    string name;
    string email;
    UserRole role;
    string password;
|};

public type CartItem record {|
    string plate;
    string start_date;
    string end_date;
    float estimated_price;
|};

public type Reservation record {|
    string reservation_id;
    string customer_id;
    string plate;
    string start_date;
    string end_date;
    float total_price;
    string booking_date;
    string status;
|};

// Request/Response types
public type AddCarResponse record {|
    boolean success;
    string message;
    string car_id;
|};

public type CreateUsersResponse record {|
    boolean success;
    string message;
    int users_created;
|};

public type UpdateCarRequest record {|
    string plate;
    Car updated_car;
|};

public type UpdateCarResponse record {|
    boolean success;
    string message;
    Car updated_car;
|};

public type RemoveCarRequest record {|
    string plate;
    string admin_id;
|};

public type RemoveCarResponse record {|
    boolean success;
    string message;
    Car[] remaining_cars;
|};

public type ListReservationsRequest record {|
    string admin_id;
|};

public type ListAvailableCarsRequest record {|
    string filter_text;
    int filter_year;
|};

public type SearchCarRequest record {|
    string plate;
|};

public type SearchCarResponse record {|
    boolean found;
    Car car;
    string message;
|};

public type AddToCartRequest record {|
    string customer_id;
    string plate;
    string start_date;
    string end_date;
|};

public type AddToCartResponse record {|
    boolean success;
    string message;
    CartItem cart_item;
|};

public type PlaceReservationRequest record {|
    string customer_id;
|};

public type PlaceReservationResponse record {|
    boolean success;
    string message;
    Reservation[] reservations;
    float total_amount;
|};

// In-memory data storage
map<Car> cars = {};
map<User> users = {};
map<CartItem[]> customerCarts = {};
map<Reservation[]> reservations = {};

// Utility functions
function isValidAdmin(string userId) returns boolean {
    User? user = users[userId];
    return user is User && user.role == ADMIN;
}

function isValidCustomer(string userId) returns boolean {
    User? user = users[userId];
    return user is User && user.role == CUSTOMER;
}

function calculateDaysBetween(string startDate, string endDate) returns int {
    // Simple calculation for demo (in real app, would parse dates properly)
    return 3;
}

function isCarAvailableForDates(string plate, string startDate, string endDate) returns boolean {
    Car? car = cars[plate];
    if car is () || car.status != AVAILABLE {
        return false;
    }
    
    // Simple availability check (in real app, would check date conflicts)
    foreach var userReservations in reservations {
        foreach var reservation in userReservations {
            if reservation.plate == plate && reservation.status == "CONFIRMED" {
                return false;
            }
        }
    }
    return true;
}

// gRPC Service Implementation
@grpc:Descriptor {
    value: "car_rental.proto"
}
service "CarRentalService" on new grpc:Listener(9090) {

    // Admin: Add a new car
    remote function AddCar(Car car) returns AddCarResponse|error {
        log:printInfo("AddCar request received for plate: " + car.plate);
        
        if cars.hasKey(car.plate) {
            return {
                success: false,
                message: "Car with plate " + car.plate + " already exists.",
                car_id: ""
            };
        }

        cars[car.plate] = car;
        
        log:printInfo("Car added successfully: " + car.plate);
        return {
            success: true,
            message: "Car added successfully",
            car_id: car.plate
        };
    }

    // Admin: Create multiple users (streaming)
    remote function CreateUsers(stream<User, grpc:Error?> clientStream) returns CreateUsersResponse|error {
        log:printInfo("CreateUsers request received");
        
        int usersCreated = 0;
        
        error? e = clientStream.forEach(function(User user) {
            if !users.hasKey(user.user_id) {
                users[user.user_id] = user;
                customerCarts[user.user_id] = [];
                usersCreated += 1;
                log:printInfo("Created user: " + user.user_id);
            }
        });

        if e is error {
            log:printError("Error creating users: " + e.message());
            return {
                success: false,
                message: "Error creating users: " + e.message(),
                users_created: usersCreated
            };
        }

        return {
            success: true,
            message: usersCreated.toString() + " users created successfully",
            users_created: usersCreated
        };
    }

    // Admin: Update car details
    remote function UpdateCar(UpdateCarRequest request) returns UpdateCarResponse|error {
        log:printInfo("UpdateCar request received for plate: " + request.plate);
        
        if !cars.hasKey(request.plate) {
            return {
                success: false,
                message: "Car with plate " + request.plate + " not found.",
                updated_car: request.updated_car
            };
        }

        cars[request.plate] = request.updated_car;
        
        log:printInfo("Car updated successfully: " + request.plate);
        return {
            success: true,
            message: "Car updated successfully",
            updated_car: request.updated_car
        };
    }

    // Admin: Remove a car
    remote function RemoveCar(RemoveCarRequest request) returns RemoveCarResponse|error {
        log:printInfo("RemoveCar request received for plate: " + request.plate);
        
        if !isValidAdmin(request.admin_id) {
            return {
                success: false,
                message: "Access denied. Admin privileges required.",
                remaining_cars: []
            };
        }

        if !cars.hasKey(request.plate) {
            return {
                success: false,
                message: "Car with plate " + request.plate + " not found.",
                remaining_cars: []
            };
        }

        _ = cars.remove(request.plate);
        Car[] remainingCars = cars.toArray();
        
        log:printInfo("Car removed successfully: " + request.plate);
        return {
            success: true,
            message: "Car removed successfully",
            remaining_cars: remainingCars
        };
    }

    // Admin: List all reservations (streaming)
    remote function ListReservations(ListReservationsRequest request) returns stream<Reservation, error?>|error {
        log:printInfo("ListReservations request received from admin: " + request.admin_id);
        
        if !isValidAdmin(request.admin_id) {
            return error("Access denied. Admin privileges required.");
        }

        Reservation[] allReservations = [];
        foreach var userReservations in reservations {
            foreach var reservation in userReservations {
                allReservations.push(reservation);
            }
        }

        return allReservations.toStream();
    }

    // Customer: List available cars (streaming)
    remote function ListAvailableCars(ListAvailableCarsRequest request) returns stream<Car, error?>|error {
        log:printInfo("ListAvailableCars request received");
        
        Car[] availableCars = [];
        
        foreach var car in cars {
            if car.status == AVAILABLE {
                boolean includeCar = true;
                
                if request.filter_text.length() > 0 {
                    string filterLower = request.filter_text.toLowerAscii();
                    string makeLower = car.make.toLowerAscii();
                    string modelLower = car.model.toLowerAscii();
                    
                    if !makeLower.includes(filterLower) && !modelLower.includes(filterLower) {
                        includeCar = false;
                    }
                }
                
                if request.filter_year > 0 && car.year != request.filter_year {
                    includeCar = false;
                }
                
                if includeCar {
                    availableCars.push(car);
                }
            }
        }

        return availableCars.toStream();
    }

    // Customer: Search for a specific car by plate
    remote function SearchCar(SearchCarRequest request) returns SearchCarResponse|error {
        log:printInfo("SearchCar request received for plate: " + request.plate);
        
        Car? car = cars[request.plate];
        
        if car is () {
            return {
                found: false,
                car: {
                    plate: "",
                    make: "",
                    model: "",
                    year: 0,
                    daily_price: 0.0,
                    mileage: 0,
                    status: UNAVAILABLE
                },
                message: "Car with plate " + request.plate + " not found."
            };
        }
        
        if car.status != AVAILABLE {
            return {
                found: false,
                car: car,
                message: "Car is not available for rental."
            };
        }

        return {
            found: true,
            car: car,
            message: "Car found and available."
        };
    }

    // Customer: Add car to cart
    remote function AddToCart(AddToCartRequest request) returns AddToCartResponse|error {
        log:printInfo("AddToCart request received for customer: " + request.customer_id);
        
        if !isValidCustomer(request.customer_id) {
            return {
                success: false,
                message: "Access denied. Customer account required.",
                cart_item: {
                    plate: "",
                    start_date: "",
                    end_date: "",
                    estimated_price: 0.0
                }
            };
        }

        if !isCarAvailableForDates(request.plate, request.start_date, request.end_date) {
            return {
                success: false,
                message: "Car is not available for the selected dates.",
                cart_item: {
                    plate: "",
                    start_date: "",
                    end_date: "",
                    estimated_price: 0.0
                }
            };
        }

        Car? car = cars[request.plate];
        if car is () {
            return {
                success: false,
                message: "Car not found.",
                cart_item: {
                    plate: "",
                    start_date: "",
                    end_date: "",
                    estimated_price: 0.0
                }
            };
        }

        int days = calculateDaysBetween(request.start_date, request.end_date);
        float estimatedPrice = car.daily_price * <float>days;

        CartItem cartItem = {
            plate: request.plate,
            start_date: request.start_date,
            end_date: request.end_date,
            estimated_price: estimatedPrice
        };

        CartItem[]? currentCart = customerCarts[request.customer_id];
        if currentCart is () {
            customerCarts[request.customer_id] = [cartItem];
        } else {
            currentCart.push(cartItem);
        }

        log:printInfo("Car added to cart for customer: " + request.customer_id);
        return {
            success: true,
            message: "Car added to cart successfully",
            cart_item: cartItem
        };
    }

    // Customer: Place reservation from cart
    remote function PlaceReservation(PlaceReservationRequest request) returns PlaceReservationResponse|error {
        log:printInfo("PlaceReservation request received for customer: " + request.customer_id);
        
        if !isValidCustomer(request.customer_id) {
            return {
                success: false,
                message: "Access denied. Customer account required.",
                reservations: [],
                total_amount: 0.0
            };
        }

        CartItem[]? cart = customerCarts[request.customer_id];
        if cart is () || cart.length() == 0 {
            return {
                success: false,
                message: "Cart is empty.",
                reservations: [],
                total_amount: 0.0
            };
        }

        foreach var item in cart {
            if !isCarAvailableForDates(item.plate, item.start_date, item.end_date) {
                return {
                    success: false,
                    message: "One or more cars are no longer available for the selected dates.",
                    reservations: [],
                    total_amount: 0.0
                };
            }
        }

        Reservation[] newReservations = [];
        float totalAmount = 0.0;
        
        foreach var item in cart {
            string reservationId = uuid:createType4AsString();
            Reservation reservation = {
                reservation_id: reservationId,
                customer_id: request.customer_id,
                plate: item.plate,
                start_date: item.start_date,
                end_date: item.end_date,
                total_price: item.estimated_price,
                booking_date: time:utcNow().toString(),
                status: "CONFIRMED"
            };
            
            newReservations.push(reservation);
            totalAmount += item.estimated_price;
            
            Car? car = cars[item.plate];
            if car is Car {
                car.status = RENTED;
                cars[item.plate] = car;
            }
        }

        Reservation[]? existingReservations = reservations[request.customer_id];
        if existingReservations is () {
            reservations[request.customer_id] = newReservations;
        } else {
            foreach var reservation in newReservations {
                existingReservations.push(reservation);
            }
        }

        customerCarts[request.customer_id] = [];

        log:printInfo("Reservation placed successfully for customer: " + request.customer_id);
        return {
            success: true,
            message: "Reservation placed successfully",
            reservations: newReservations,
            total_amount: totalAmount
        };
    }
}

public function main2() returns error? {
    log:printInfo("Starting Car Rental gRPC Server on port 9090...");
    
    initializeDemoData();
    
    log:printInfo("Server started successfully!");
    log:printInfo("Available services:");
    log:printInfo("- AddCar (Admin)");
    log:printInfo("- CreateUsers (Admin)"); 
    log:printInfo("- UpdateCar (Admin)");
    log:printInfo("- RemoveCar (Admin)");
    log:printInfo("- ListReservations (Admin)");
    log:printInfo("- ListAvailableCars (Customer)");
    log:printInfo("- SearchCar (Customer)");
    log:printInfo("- AddToCart (Customer)");
    log:printInfo("- PlaceReservation (Customer)");
    
    return ();
}

function initializeDemoData() {
    cars["ABC123"] = {
        plate: "ABC123",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        daily_price: 50.0,
        mileage: 15000,
        status: AVAILABLE
    };
    
    cars["DEF456"] = {
        plate: "DEF456",
        make: "Honda",
        model: "Civic",
        year: 2021,
        daily_price: 45.0,
        mileage: 22000,
        status: AVAILABLE
    };
    
    cars["GHI789"] = {
        plate: "GHI789",
        make: "BMW",
        model: "X3",
        year: 2023,
        daily_price: 85.0,
        mileage: 8000,
        status: AVAILABLE
    };
    
    users["admin1"] = {
        user_id: "admin1",
        name: "Admin User",
        email: "admin@carrental.com",
        role: ADMIN,
        password: "admin123"
    };
    
    users["customer1"] = {
        user_id: "customer1",
        name: "John Doe",
        email: "john@email.com",
        role: CUSTOMER,
        password: "customer123"
    };
    
    users["customer2"] = {
        user_id: "customer2",
        name: "Jane Smith",
        email: "jane@email.com",
        role: CUSTOMER,
        password: "customer456"
    };
    
    customerCarts["customer1"] = [];
    customerCarts["customer2"] = [];
    
    log:printInfo("Demo data initialized:");
    log:printInfo("- Cars: " + cars.length().toString());
    log:printInfo("- Users: " + users.length().toString());
}