import ballerina/time;

public type Status record {
    int id;
    string name;
};

public type Component record {
    int id;
    string name;
    string description?;
};

public type Schedule record {
    int id;
    string name;
    string frequency;
    time:Date nextDue;
};

public type Task record {
    int id;
    string description;
    boolean done;
};

public type WorkOrder record {
    string id;
    string description;
    Status status;
    Task[] tasks;
};

public type Asset record {
    int id;
    string assetTag; // unique key
    string name;
    string faculty;
    string department;
    Status status;
    string acquiredDate;
    Component[] components;
    Schedule[] schedules;
    WorkOrder[] workOrders;
};
