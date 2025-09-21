import ballerina/http;
import ballerina/io;

const string BASE_URL = "http://localhost:3000/api";

http:Client httpClient = check new (BASE_URL);

function clearScreen() {
    // ANSI escape code to clear screen & reset cursor
    io:print("\u{1B}[2J\u{1B}[H");
}

public function main() returns error? {
    while true {
        clearScreen();
        printHeader();
        printMenu();
        string choice = io:readln("\nEnter your choice #: ");
        match choice {
            "1" => {
                check getAllAssets();
            }
            "2" => {
                check getAssetsByFaculty();
            }
            "3" => {
                check getOverdueAssets();
            }
            "4" => {
                check addAsset();
            }
            "5" => {
                check updateAsset();
            }
            "6" => {
                check deleteAsset();
            }
            "7" => {
                check addComponent();
            }
            "8" => {
                check removeComponent();
            }
            "9" => {
                string confirm = io:readln("Are you sure you want to exit? (y/n): ");
                if confirm.toLowerAscii() == "y" {
                    printBoxedText("Exiting the program. Goodbye!", "yellow");
                    return;
                } else {
                    printBoxedText("Exit cancelled. Returning to Menu.", "cyan");
                }
            }
            _ => {
                printBoxedText("Invalid choice. Please try again.", "red");
            }
        }
    }
}

function printHeader() {
    io:println(color("cyan", "\n+===============================================+\n" +
                            "|                                               |\n" +
                            "|         NUST Asset Management CLI System      |\n" +
                            "|                                               |\n" +
                            "+===============================================+\n"));
}

function printMenu() {
    io:println(color("green", "\n+------------------- Menu ---------------------+\n" +
                            "|                                              |\n" +
                            "|  1. View all assets                          |\n" +
                            "|  2. View assets by faculty                   |\n" +
                            "|  3. View overdue assets                      |\n" +
                            "|  4. Add a new asset                          |\n" +
                            "|  5. Update an asset                          |\n" +
                            "|  6. Delete an asset                          |\n" +
                            "|  7. Add a component to asset                 |\n" +
                            "|  8. Remove a component from asset            |\n" +
                            "|  9. Exit                                     |\n" +
                            "|                                              |\n" +
                            "+----------------------------------------------+\n"));
}

// 1. View all assets
function getAllAssets() returns error? {
    printBoxedText("Fetching all assets...", "blue");
    json response = check httpClient->get("/all_assets");
    printJsonResponse(response);
}

// 2. View assets by faculty
function getAssetsByFaculty() returns error? {
    string faculty = promptForInput("Enter faculty name: ");
    printBoxedText("Fetching assets for faculty...", "blue");
    json response = check httpClient->get("/faculty_assets/" + faculty);
    printJsonResponse(response);
}

// 3. View overdue assets
function getOverdueAssets() returns error? {
    printBoxedText("Fetching overdue assets...", "blue");
    json response = check httpClient->get("/overdue_assets");
    printJsonResponse(response);
}

// 4. Add a new asset
function addAsset() returns error? {
    printBoxedText("Adding new asset", "blue");
    json status = {
        "id": check int:fromString(promptForInput("Enter status id (e.g., 1 for ACTIVE): ")),
        "name": promptForInput("Enter status name (e.g., ACTIVE): ")
    };
    json asset = {
        "assetTag": promptForInput("Enter asset tag: "),
        "name": promptForInput("Enter asset name: "),
        "faculty": promptForInput("Enter faculty: "),
        "department": promptForInput("Enter department: "),
        "status": status,
        "acquiredDate": promptForInput("Enter acquired date (YYYY-MM-DD): "),
        "components": [],
        "schedules": [],
        "workOrders": []
    };
    json response = check httpClient->post("/add_asset", asset);
    printJsonResponse(response);
}

// 5. Update an asset
function updateAsset() returns error? {
    string assetTag = promptForInput("Enter asset tag to update: ");
    printBoxedText("Updating asset", "blue");
    map<string> asset = {};

    addToMapIfNotEmpty(asset, "name", "Enter new asset name (press Enter to skip): ");
    addToMapIfNotEmpty(asset, "faculty", "Enter new faculty (press Enter to skip): ");
    addToMapIfNotEmpty(asset, "department", "Enter new department (press Enter to skip): ");
    string statusId = promptForInput("Enter new status id (press Enter to skip): ");
    string statusName = promptForInput("Enter new status name (press Enter to skip): ");
    if statusId != "" && statusName != "" {
        // asset["status"] = {"id": check int:fromString(statusId), "name": statusName};
    }
    addToMapIfNotEmpty(asset, "acquiredDate", "Enter new acquired date (YYYY-MM-DD, press Enter to skip): ");

    if asset.length() == 0 {
        printBoxedText("No updates provided. Skipping update operation.", "yellow");
        return;
    }

    json response = check httpClient->put("/update_asset/" + assetTag, asset.toJson());
    printJsonResponse(response);
}

// 6. Delete an asset
function deleteAsset() returns error? {
    string assetTag = promptForInput("Enter asset tag to delete: ");
    printBoxedText("Deleting asset...", "blue");
    json response = check httpClient->delete("/delete_asset/" + assetTag);
    printJsonResponse(response);
}

// 7. Add a component to asset
function addComponent() returns error? {
    string assetTag = promptForInput("Enter asset tag to add component to: ");
    printBoxedText("Adding component...", "blue");
    json component = {
        "name": promptForInput("Enter component name: "),
        "description": promptForInput("Enter component description: ")
    };
    json response = check httpClient->post("/add_component/" + assetTag, component);
    printJsonResponse(response);
}

// 8. Remove a component from asset
function removeComponent() returns error? {
    string assetTag = promptForInput("Enter asset tag to remove component from: ");
    string componentName = promptForInput("Enter component name to remove: ");
    printBoxedText("Removing component...", "blue");
    json response = check httpClient->delete("/remove_component/" + assetTag + "/" + componentName);
    printJsonResponse(response);
}

// Helper functions
function promptForInput(string prompt) returns string {
    return io:readln(color("cyan", prompt)).trim();
}

function addToMapIfNotEmpty(map<string> m, string key, string prompt) {
    string? value = promptForInput(prompt);
    if value is string && value != "" {
        m[key] = value;
    }
}

function printJsonResponse(json response) {
    io:println("\nResponse:");
    io:println(color("green", response.toJsonString()));
}

function color(string color, string text) returns string {
    match color {
        "red" => {
            return "\u{001b}[31m" + text + "\u{001b}[0m";
        }
        "green" => {
            return "\u{001b}[32m" + text + "\u{001b}[0m";
        }
        "yellow" => {
            return "\u{001b}[33m" + text + "\u{001b}[0m";
        }
        "blue" => {
            return "\u{001b}[34m" + text + "\u{001b}[0m";
        }
        "magenta" => {
            return "\u{001b}[35m" + text + "\u{001b}[0m";
        }
        "cyan" => {
            return "\u{001b}[36m" + text + "\u{001b}[0m";
        }
        _ => {
            return text;
        }
    }
}

function printBoxedText(string text, string boxColor) {
    int width = text.length() + 4;
    string horizontalBorder = createBorder(width);

    io:println(color(boxColor, "+" + horizontalBorder + "+"));
    io:println(color(boxColor, "|  " + text + "  |"));
    io:println(color(boxColor, "+" + horizontalBorder + "+"));
}

function createBorder(int width) returns string {
    string border = "";
    int i = 0;
    while i < width {
        border = border + "-";
        i = i + 1;
    }
    return border;
}
