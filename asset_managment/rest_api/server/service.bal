import ballerina/http;
import ballerina/sql;

service /api on new http:Listener(3000) {

    resource function get hello() returns string|error {
        // Query the DB
        stream<record {int id; string name;}, error?> result = db->query(`SELECT id, name FROM users`);

        string output = "Users:\n";

        // Iterate over the result stream
        error? e = result.forEach(function(record {int id; string name;} user) {
            output += "ID: " + user.id.toString() + ", Name: " + user.name + "\n";
        });

        if (e is error) {
            return e;
        }

        return output;
    }

    // Retrieve all assets
    resource function get all_assets() returns Asset[]|error {
        stream<Asset, sql:Error?> assetsStream = db->query(`SELECT * FROM Assets`);
        Asset[] assetList = [];
        check from Asset asset in assetsStream
            do {
                assetList.push(asset);
            };
        return assetList;
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
        VALUES (${asset.assetTag}, ${asset.name}, ${asset.faculty}, ${asset.department}, ${asset.status.id}, ${asset.acquiredDate})
    `);
        // Optionally add related components/schedules/workorders here
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
    resource function put update_asset/[string assetTag](Asset asset) returns Asset[]|error {
        boolean updated = false;

        if asset.name is string {
            _ = check db->execute(`
            UPDATE Assets SET name = ${asset.name} WHERE assetTag = ${assetTag}
        `);
            updated = true;
        }
        if asset.faculty is string {
            _ = check db->execute(`
            UPDATE Assets SET faculty = ${asset.faculty} WHERE assetTag = ${assetTag}
        `);
            updated = true;
        }
        if asset.department is string {
            _ = check db->execute(`
            UPDATE Assets SET department = ${asset.department} WHERE assetTag = ${assetTag}
        `);
            updated = true;
        }
        if asset.status.id is int {
            _ = check db->execute(`
            UPDATE Assets SET status = ${asset.status.id} WHERE assetTag = ${assetTag}
        `);
            updated = true;
        }
        if asset.acquiredDate is string {
            _ = check db->execute(`
            UPDATE Assets SET acquiredDate = ${asset.acquiredDate} WHERE assetTag = ${assetTag}
        `);
            updated = true;
        }

        if !updated {
            return error("No fields provided for update");
        }

        stream<Asset, sql:Error?> assetStream = db->query(
        `SELECT * FROM Assets WHERE assetTag = ${assetTag}`
        );
        Asset[] assetList = [];
        check from Asset a in assetStream
            do {
                assetList.push(a);
            };
        return assetList;
    }

    // Delete an asset; return deleted asset
    resource function delete delete_asset/[string assetTag]() returns Asset[]|error {
        stream<Asset, sql:Error?> assetStream = db->query(
            `SELECT * FROM Assets WHERE assetTag = ${assetTag}`
        );
        Asset[] assetList = [];
        check from Asset asset in assetStream
            do {
                assetList.push(asset);
            };
        if assetList.length() == 0 {
            return error("Asset not found.");
        }

        // Delete all mappings related to the asset in Components, Schedules, WorkOrders, Tasks before deleting the asset itself
        _ = check db->execute(`DELETE FROM Components WHERE assetTag = ${assetTag}`);
        _ = check db->execute(`DELETE FROM Schedules WHERE assetTag = ${assetTag}`);
        _ = check db->execute(`DELETE FROM WorkOrders WHERE assetTag = ${assetTag}`);

        _ = check db->execute(`DELETE FROM Assets WHERE assetTag = ${assetTag}`);

        return assetList;
    }

    // Add a component to asset
    resource function post add_component/[string assetTag](Component component) returns Component[]|error {
        _ = check db->execute(`
            INSERT INTO Components (assetTag, name, description)
            VALUES (${assetTag}, ${component.name}, ${component.description})
        `);
        stream<Component, sql:Error?> componentStream = db->query(
            `SELECT * FROM Components WHERE assetTag = ${assetTag} AND name = ${component.name}`
        );
        Component[] componentList = [];
        check from Component c in componentStream
            do {
                componentList.push(c);
            };
        return componentList;
    }

    // Remove a component from an asset
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
        _ = check db->execute(`
            DELETE FROM Components WHERE id = ${id}
        `);
        return componentList;
    }

    resource function delete remove_task/[int id]() returns Task[]|error {
        stream<Task, sql:Error?> taskStream = db->query(
            `SELECT * FROM Task WHERE id = ${id}`
        );
        Task[] taskList = [];
        check from Task c in taskStream
            do {
                taskList.push(c);
            };
        if taskList.length() == 0 {
            return error("Task not found.");
        }
        _ = check db->execute(`
            DELETE FROM Task WHERE id = ${id}
        `);
        return taskList;
    }

    resource function delete remove_WorkOrder/[int id]() returns WorkOrder[]|error {
        stream<WorkOrder, sql:Error?> workorderStream = db->query(
            `SELECT * FROM WorkOrder WHERE id = ${id}`
        );
        WorkOrder[] workOrderList = [];
        check from WorkOrder c in workorderStream
            do {
                workOrderList.push(c);
            };
        if workOrderList.length() == 0 {
            return error("WorkOrder not found.");
        }
        _ = check db->execute(`
            DELETE FROM WorkOrder WHERE id = ${id}
        `);
        return workOrderList;
    }

    resource function delete remove_Schedule/[int id]() returns Schedule[]|error {
        stream<Schedule, sql:Error?> scheduleStream = db->query(
            `SELECT * FROM Schedule WHERE id = ${id}`
        );
        Schedule[] scheduleList = [];
        check from Schedule c in scheduleStream
            do {
                scheduleList.push(c);
            };
        if scheduleList.length() == 0 {
            return error("WorkOrder not found.");
        }
        _ = check db->execute(`
            DELETE FROM WorkOrder WHERE id = ${id}
        `);
        return scheduleList;
    }

}
