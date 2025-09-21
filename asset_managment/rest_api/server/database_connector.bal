import ballerinax/mysql;
import ballerinax/mysql.driver as _;

final mysql:Client db = check new (
    host = "localhost",
    user = "root",
    password = "password",
    port = 3306,
    database = "tutorial"
);
