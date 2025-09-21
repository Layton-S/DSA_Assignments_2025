```markdown
# Asset Management REST API

This project is a Ballerina-based REST API for managing institutional assets such as laboratory equipment, vehicles, etc. It connects to a MySQL database for persistence and provides CRUD operations for assets, components, schedules, work orders, and tasks.

## Features

- Manage Assets (add, update, delete, list all, filter by faculty, list overdue)
- Manage Components associated with assets
- Manage Schedules for maintenance
- Manage Tasks within work orders
- Manage Work Orders
- MySQL-backed persistence layer
- Modular structure (server + client separation)

---

## Configuration

Edit `server/database_connector.bal` with your database credentials:

```ballerina
final mysql:Client db = check new (
    host = "localhost",
    user = "root",
    password = "password",
    port = 3306,
    database = "asset_managment"
);


## Running the Project

### Start the Server

```bash
cd server
bal run


Server runs on: `http://localhost:3000/api`

### Run the Client

```bash
cd client
bal run


## API Endpoints

### Assets

* `GET /api/all_assets` → Get all assets
* `GET /api/faculty_assets/{faculty}` → Get assets by faculty
* `GET /api/overdue_assets` → Get overdue assets
* `POST /api/add_asset` → Add a new asset
* `PUT /api/update_asset/{assetTag}` → Update an asset
* `DELETE /api/delete_asset/{assetTag}` → Delete an asset

### Components

* `POST /api/add_component/{assetTag}` → Add component to an asset
* `DELETE /api/remove_component/{id}` → Remove a component

### Work Orders & Tasks

* `DELETE /api/remove_WorkOrder/{id}`
* `DELETE /api/remove_task/{id}`

### Schedules

* `DELETE /api/remove_Schedule/{id}`

---

## Tech Stack

* Ballerina (Backend framework)
* MySQL (Database)
* REST API (JSON responses)

```

