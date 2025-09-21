import ballerina/http;
import ballerina/sql;

// Helper to populate Asset with nested entities
function populateAsset(Asset asset) returns Asset|error {
    stream<Component, sql:Error?> componentStream = db->query(
        `SELECT * FROM Components WHERE assetId = ${asset.id}`
    );
    Component[] components = [];
    check from Component c in componentStream
        do {
            components.push(c);
        };
    asset.components = components;

    stream<Schedule, sql:Error?> scheduleStream = db->query(
        `SELECT * FROM Schedules WHERE assetId = ${asset.id}`
    );
    Schedule[] schedules = [];
    check from Schedule s in scheduleStream
        do {
            schedules.push(s);
        };
    asset.schedules = schedules;

    stream<WorkOrder, sql:Error?> workOrderStream = db->query(
        `SELECT * FROM WorkOrder WHERE assetId = ${asset.id}`
    );
    WorkOrder[] workOrders = [];
    check from WorkOrder w in workOrderStream
        do {
            workOrders.push(w);
        };
    asset.workOrders = workOrders;

    return asset;
}

service /api on new http:Listener(3000) {

    // Retrieve all assets with nested data
    resource function get all_assets() returns Asset[]|error {
        Asset[] assets = [];
        stream<record {
            int id;
            string assetTag;
            string name;
            string faculty;
            string department;
            int status;
            string acquiredDate;
        }, sql:Error?> assetStream = db->query(
            `SELECT id, assetTag, name, faculty, department, status, acquiredDate FROM Assets`
        );
        check from var row in assetStream
            do {
                Asset a = {
                    id: row.id,
                    assetTag: row.assetTag,
                    name: row.name,
                    faculty: row.faculty,
                    department: row.department,
                    status: row.status,
                    acquiredDate: row.acquiredDate.toString(),
                    components: [],
                    schedules: [],
                    workOrders: []
                };
                a = check populateAsset(a);
                assets.push(a);
            };
        return assets;
    }

    // Delete an asset safely with related entities
    resource function delete delete_asset/[int id]() returns Asset[]|error {
        stream<Asset, sql:Error?> assetStream = db->query(
            `SELECT * FROM Assets WHERE id = ${id}`
        );
        Asset[] assetList = [];
        check from Asset asset in assetStream
            do {
                assetList.push(asset);
            };
        if assetList.length() == 0 {
            return error("Asset not found.");
        }

        // Delete related entities by assetId
        _ = check db->execute(`DELETE FROM Components WHERE assetId = ${id}`);
        _ = check db->execute(`DELETE FROM Schedules WHERE assetId = ${id}`);
        _ = check db->execute(`DELETE FROM WorkOrder WHERE assetId = ${id}`);
        _ = check db->execute(`DELETE FROM Assets WHERE id = ${id}`);

        return assetList;
    }

    // Add a component to an asset
    resource function post add_component/[int assetId](Component component) returns Component[]|error {
        _ = check db->execute(`
            INSERT INTO Components (assetId, name, description)
            VALUES (${assetId}, ${component.name}, ${component.description})
        `);
        stream<Component, sql:Error?> componentStream = db->query(
            `SELECT * FROM Components WHERE assetId = ${assetId} AND name = ${component.name}`
        );
        Component[] componentList = [];
        check from Component c in componentStream
            do {
                componentList.push(c);
            };
        return componentList;
    }

    // Remove a component
    resource function delete remove_component/[int id]() returns Component[]|error {
        stream<Component, sql:Error?> componentStream = db->query(
            `SELECT * FROM Components WHERE id = ${id}`
        );
        Component[] componentList = [];
        check from Component c in componentStream
            do {
                componentList.push(c);
            };
        if componentList.length() == 0 {
            return error("Component not found.");
        }
        _ = check db->execute(`DELETE FROM Components WHERE id = ${id}`);
        return componentList;
    }

    // Retrieve assets by faculty
    resource function get faculty_assets/[string faculty]() returns Asset[]|error {
        stream<Asset, sql:Error?> assetsStream = db->query(
            `SELECT * FROM Assets WHERE faculty = ${faculty}`
        );
        Asset[] assetList = [];
        check from Asset asset in assetsStream
            do {
                assetList.push(asset);
            };
        return assetList;
    }

    // Retrieve overdue assets (with overdue schedules)
    resource function get overdue_assets() returns Asset[]|error {
        stream<Asset, sql:Error?> assetsStream = db->query(`
            SELECT DISTINCT a.*
            FROM Assets a
            JOIN Schedules s ON a.assetTag = s.assetTag
            WHERE s.nextDue <= CURRENT_DATE
        `);
        Asset[] assetList = [];
        check from Asset asset in assetsStream
            do {
                assetList.push(asset);
            };
        return assetList;
    }

    // Add a new asset
    resource function post add_asset(Asset asset) returns Asset[]|error {
        _ = check db->execute(`
            INSERT INTO Assets (assetTag, name, faculty, department, status, acquiredDate)
            VALUES (${asset.assetTag}, ${asset.name}, ${asset.faculty}, ${asset.department}, ${asset.status}, ${asset.acquiredDate})
        `);
        stream<Asset, sql:Error?> assetStream = db->query(
            `SELECT * FROM Assets WHERE assetTag = ${asset.assetTag}`
        );
        Asset[] assetList = [];
        check from Asset a in assetStream
            do {
                assetList.push(a);
            };
        return assetList;
    }

    // Update an asset
    resource function put update_asset/[int id](Asset asset) returns Asset[]|error {
        boolean updated = false;

        if asset.name is string {
            _ = check db->execute(`UPDATE Assets SET name = ${asset.name} WHERE id = ${id}`);
            updated = true;
        }
        if asset.faculty is string {
            _ = check db->execute(`UPDATE Assets SET faculty = ${asset.faculty} WHERE id = ${id}`);
            updated = true;
        }
        if asset.department is string {
            _ = check db->execute(`UPDATE Assets SET department = ${asset.department} WHERE id = ${id}`);
            updated = true;
        }
        if asset.status is int {
            _ = check db->execute(`UPDATE Assets SET status = ${asset.status} WHERE id = ${id}`);
            updated = true;
        }
        if asset.acquiredDate is string {
            _ = check db->execute(`UPDATE Assets SET acquiredDate = ${asset.acquiredDate} WHERE id = ${id}`);
            updated = true;
        }
        if !updated {
            return error("No fields provided for update");
        }

        stream<Asset, sql:Error?> assetStream = db->query(
            `SELECT * FROM Assets WHERE id = ${id}`
        );
        Asset[] assetList = [];
        check from Asset a in assetStream
            do {
                assetList.push(a);
            };
        return assetList;
    }

    // Add a status
    resource function post add_status(Status status) returns Status[]|error {
        _ = check db->execute(`
            INSERT INTO Status (name) VALUES (${status.name})
        `);
        stream<Status, sql:Error?> statusStream = db->query(
            `SELECT * FROM Status WHERE name = ${status.name}`
        );
        Status[] statusList = [];
        check from Status s in statusStream
            do {
                statusList.push(s);
            };
        return statusList;
    }

    // Remove a status
    resource function delete remove_status/[int id]() returns Status[]|error {
        stream<Status, sql:Error?> statusStream = db->query(
            `SELECT * FROM Status WHERE id = ${id}`
        );
        Status[] statusList = [];
        check from Status s in statusStream
            do {
                statusList.push(s);
            };
        if statusList.length() == 0 {
            return error("Status not found.");
        }
        _ = check db->execute(`DELETE FROM Status WHERE id = ${id}`);
        return statusList;
    }

    // Remove a task
    resource function delete remove_task/[int id]() returns Task[]|error {
        stream<Task, sql:Error?> taskStream = db->query(
            `SELECT * FROM Task WHERE id = ${id}`
        );
        Task[] taskList = [];
        check from Task t in taskStream
            do {
                taskList.push(t);
            };
        if taskList.length() == 0 {
            return error("Task not found.");
        }
        _ = check db->execute(`DELETE FROM Task WHERE id = ${id}`);
        return taskList;
    }

    // Remove a work order
    resource function delete remove_workorder/[int id]() returns WorkOrder[]|error {
        stream<WorkOrder, sql:Error?> workOrderStream = db->query(
            `SELECT * FROM WorkOrder WHERE id = ${id}`
        );
        WorkOrder[] workOrderList = [];
        check from WorkOrder w in workOrderStream
            do {
                workOrderList.push(w);
            };
        if workOrderList.length() == 0 {
            return error("WorkOrder not found.");
        }
        _ = check db->execute(`DELETE FROM WorkOrder WHERE id = ${id}`);
        return workOrderList;
    }

    // Remove a schedule
    resource function delete remove_schedule/[int id]() returns Schedule[]|error {
        stream<Schedule, sql:Error?> scheduleStream = db->query(
            `SELECT * FROM Schedules WHERE id = ${id}`
        );
        Schedule[] scheduleList = [];
        check from Schedule s in scheduleStream
            do {
                scheduleList.push(s);
            };
        if scheduleList.length() == 0 {
            return error("Schedule not found.");
        }
        _ = check db->execute(`DELETE FROM Schedules WHERE id = ${id}`);
        return scheduleList;
    }
}
