CREATE TABLE Departments(
 	name TEXT,
	abr TEXT NOT NULL UNIQUE,
	PRIMARY KEY(name)
);

CREATE TABLE Programs(
	name TEXT,
	abr TEXT NOT NULL,
	PRIMARY KEY(name)
);

CREATE TABLE Branches(
	name TEXT,
	program TEXT REFERENCES Programs(name),
	PRIMARY KEY(name, program)
);

CREATE TABLE DepHostingProgram(
	department TEXT REFERENCES Departments(name),
	program TEXT REFERENCES Programs(name),
	PRIMARY KEY(department, program)
);


CREATE TABLE Students (
	idnr NUMERIC(10) PRIMARY KEY,
	name TEXT NOT NULL,
	login TEXT UNIQUE NOT NULL,
	program TEXT NOT NULL REFERENCES Programs(name)
);

CREATE TABLE Courses (
	code TEXT PRIMARY KEY,
	name TEXT NOT NULL,
	credits INT NOT NULL
);

CREATE TABLE DepGivesCourse(
	course TEXT REFERENCES Courses(code),
	department TEXT REFERENCES Departments(name),
	PRIMARY KEY(course)
);

CREATE TABLE Prerequisites(
	course TEXT REFERENCES Courses(code),
	prerequisite TEXT REFERENCES Courses(code),
	PRIMARY KEY(course, prerequisite)
);

CREATE TABLE LimitedCourses (
	code TEXT REFERENCES Courses(code),
	seats NUMERIC(1, 0) NOT NULL,
	PRIMARY KEY(code)
);

CREATE TABLE Classifications (
	name TEXT PRIMARY KEY
);

CREATE TABLE Classified (
	course TEXT REFERENCES Courses(code),
	classification TEXT REFERENCES Classifications(name),
	PRIMARY KEY (course, classification)
);

CREATE TABLE MandatoryProgram(
	course TEXT REFERENCES Courses(code),
	program TEXT REFERENCES Programs(name),
	PRIMARY KEY(course, program)
);

CREATE TABLE MandatoryBranch(
	course TEXT REFERENCES Courses(code),
	branch TEXT,
	program TEXT,
	FOREIGN KEY (branch, program) REFERENCES Branches(name, program),
	PRIMARY KEY(course, branch, program)
);

CREATE TABLE RecommendedBranch(
	course TEXT REFERENCES Courses(code),
	branch TEXT,
	program TEXT,
	FOREIGN KEY (branch, program) REFERENCES Branches(name, program),
	PRIMARY KEY(course, branch, program)
);

CREATE TABLE Registered(
	student NUMERIC(10) REFERENCES Students(idnr),
	course TEXT REFERENCES Courses(code),
	PRIMARY KEY(student, course)
);

CREATE TABLE Taken(
	student NUMERIC(10) REFERENCES Students(idnr),
	course TEXT REFERENCES Courses(code),
	grade CHAR(1) NOT NULL,
	PRIMARY KEY(student, course)
);

CREATE TABLE WaitingList(
	student NUMERIC(10) REFERENCES Students(idnr),
	course TEXT REFERENCES Limitedcourses(code),
	position SERIAL NOT NULL,
	PRIMARY KEY(student, course)
);


CREATE TABLE StudentBranch(
	student NUMERIC(10) REFERENCES Students(idnr),
	branch TEXT,
	program TEXT,
	FOREIGN KEY(branch, program) REFERENCES Branches(name, program),
	PRIMARY KEY(student, branch)
);


CREATE TABLE CourseDepartment(
	course TEXT REFERENCES Courses(code),
	department TEXT REFERENCES Departments(name),
	PRIMARY KEY(course)
);


