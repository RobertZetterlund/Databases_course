DROP DATABASE exercise;
CREATE DATABASE exercise;

CREATE TABLE Departments (
        department_id INT NOT NULL,
        department_name TEXT NOT NULL,
        CONSTRAINT department_pk PRIMARY KEY (department_id)
);

CREATE TABLE Employees (
    employee_number INT PRIMARY KEY,
    employee_name TEXT NOT NULL,
    department INT REFERENCES Departments(department_id),
    salary INT NOT NULL
);

INSERT INTO Departments (department_id,department_name) VALUES (0,'CSE');
INSERT INTO Departments VALUES (1, 'DIT');

INSERT INTO Employees VALUES (0, 'Matti', 0, 100000);


-- EXERSICE 2

CREATE TABLE Suppliers (
    sid INT PRIMARY KEY,
    sname TEXT NOT NULL,
    city TEXT NOT NULL,
    street TEXT NOT NULL
);

INSERT INTO Suppliers VALUES  (0, 'Volvo', 'Gothenbourg', 'Hisingen');
INSERT INTO Suppliers VALUES  (1, 'INTEL', 'Seattle', 'Street');


Create TABLE Parts (
    pid INT PRIMARY KEY,
    pname TEXT NOT NULL,
    color TEXT NOT NULL CHECK (color IN ('red','green','blue')) 
    -- vi ser till att endast 3 färger accepteras
);

INSERT INTO Parts VALUES  (0, 'x40', 'red');
INSERT INTO Parts VALUES  (1, 'v44', 'green');
INSERT INTO Parts VALUES  (2, 'i7-440', 'blue');
INSERT INTO Parts VALUES  (3, 'v50', 'red');



CREATE TABLE Catalog (
    pid INT NOT NULL REFERENCES Parts(pid),
    sid INT NOT NULL REFERENCES Suppliers(sid),
    cost FLOAT NOT NULL,
    PRIMARY KEY(pid,sid) -- detta är ett par, vi ser att då kan man ha flera suppliers för olika parts
);

INSERT INTO Catalog VALUES  (0,0,5000.2);
INSERT INTO Catalog VALUES  (1,0,1000.3);
INSERT INTO Catalog VALUES  (2,1,100.3);

SELECT sname AS Name
FROM Suppliers
WHERE sid IN (      SELECT Suppliers.sid
                    FROM Catalog, Parts, Suppliers
                    WHERE Parts.pid = Catalog.pid
                        AND  Suppliers.sid = Catalog.sid
                        AND  color!= 'blue');



-- EXERCISE 3

DROP TABLE Employees;

CREATE TABLE Employees (
    empID TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    department INT NOT NULL,
    salary INT NOT NULL);

-- b max salary for employees

SELECT department, MAX(salary)
FROM Employees
GROUP BY department;

-- salary above the max of dept 5
SELECT name
FROM Employees
where salary > (
    SELECT MAX(salary)
    FROM Employees
    WHERE department = 5
    GROUP BY department);

-- c find emplyee records containing joe

SELECT * 
FROM Employees
WHERE LOWER(name) LIKE '%joe%';

-- Exercise 4

DROP TABLE Employees;
CREATE TABLE Employees (
    employeeID INT PRIMARY KEY,
    employeeName TEXT NOT NULL,
    street TEXT NOT NULL,
    city TEXT NOT NULL
);

CREATE TABLE Companies (
    companyID INT PRIMARY KEY,
    companyName TEXT NOT NULL,
    companyCity TEXT NOT NULL
);

CREATE TABLE Works (
    Employee INT NOT NULL REFERENCES Employees(employeeID),
    company INT NOT NULL REFERENCES Companies(companyID),
    salary INT NOT NULL,
    PRIMARY KEY(employee,company)
);

CREATE TABLE Manages (
    manager INT NOT NULL REFERENCES Employees(employeeID),
    employee INT NOT NULL REFERENCES Employees(employeeID),
    PRIMARY KEY (manager,employee)
);