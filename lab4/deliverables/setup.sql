-- setup.sql: SQL code that sets up your database for testing the triggers.
-- This will normally be the concatenation of files tables.sql, insert.sql and views.sql from Task 2.
-- We must be able to test your triggers by executing the files setup.sql and triggers.sql,
-- in that order.

-- start tables.sql

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

-- end tables.sql

-- start inserts.sql

INSERT INTO Departments VALUES ('Dep1','D1');

INSERT INTO Programs VALUES ('Prog1','P1');
INSERT INTO Programs VALUES ('Prog2','P2');

INSERT INTO DepHostingProgram VALUES ('Dep1', 'Prog1');
INSERT INTO DepHostingProgram VALUES ('Dep1', 'Prog2');

INSERT INTO Branches VALUES ( 'B1', 'Prog1');
INSERT INTO Branches VALUES ( 'B2', 'Prog1');
INSERT INTO Branches VALUES ( 'B1', 'Prog2');

INSERT INTO Students VALUES (1111111111,'S1','ls1', 'Prog1');
INSERT INTO Students VALUES (2222222222,'S2','ls2', 'Prog1');
INSERT INTO Students VALUES (3333333333,'S3','ls3', 'Prog2');
INSERT INTO Students VALUES (4444444444,'S4','ls4', 'Prog1');


INSERT INTO Courses VALUES ('CCC111','C1',10);
INSERT INTO Courses VALUES ('CCC222','C2',20);
INSERT INTO Courses VALUES ('CCC333','C3',30);
INSERT INTO Courses VALUES ('CCC444','C4',40);
INSERT INTO Courses VALUES ('CCC555','C5',50);

INSERT INTO Prerequisites VALUES ('CCC555', 'CCC111');


INSERT INTO DepGivesCourse VALUES ('CCC111','Dep1');
INSERT INTO DepGivesCourse VALUES ('CCC222','Dep1');
INSERT INTO DepGivesCourse VALUES ('CCC333','Dep1');
INSERT INTO DepGivesCourse VALUES ('CCC444','Dep1');
INSERT INTO DepGivesCourse VALUES ('CCC555','Dep1');

INSERT INTO LimitedCourses VALUES ('CCC222',1);
INSERT INTO LimitedCourses VALUES ('CCC333',2);

INSERT INTO Classifications VALUES ('math');
INSERT INTO Classifications VALUES ('research');
INSERT INTO Classifications VALUES ('seminar');

INSERT INTO Classified VALUES ('CCC333','math');
INSERT INTO Classified VALUES ('CCC444','research');
INSERT INTO Classified VALUES ('CCC444','seminar');

INSERT INTO StudentBranch VALUES (2222222222,'B1');
INSERT INTO StudentBranch VALUES (3333333333,'B1');
INSERT INTO StudentBranch VALUES (4444444444,'B1');

INSERT INTO MandatoryProgram VALUES ('CCC111','Prog1');

INSERT INTO MandatoryBranch VALUES ('CCC333', 'B1', 'Prog1');
INSERT INTO MandatoryBranch VALUES ('CCC555', 'B1', 'Prog2');

INSERT INTO RecommendedBranch VALUES ('CCC222', 'B1', 'Prog1');

INSERT INTO Registered VALUES (1111111111,'CCC111');
INSERT INTO Registered VALUES (1111111111,'CCC222');
INSERT INTO Registered VALUES (1111111111,'CCC333');

INSERT INTO Registered VALUES (4444444444,'CCC333');

INSERT INTO Registered VALUES (4444444444,'CCC222');



INSERT INTO Registered VALUES (2222222222,'CCC222');

INSERT INTO Taken VALUES(4444444444,'CCC111','5');
INSERT INTO Taken VALUES(4444444444,'CCC222','5');
INSERT INTO Taken VALUES(4444444444,'CCC333','5');
INSERT INTO Taken VALUES(4444444444,'CCC444','5');

INSERT INTO Taken VALUES(1111111111,'CCC111','3');
INSERT INTO Taken VALUES(1111111111,'CCC222','3');
INSERT INTO Taken VALUES(1111111111,'CCC333','3');
INSERT INTO Taken VALUES(1111111111,'CCC444','3');

INSERT INTO Taken VALUES(2222222222,'CCC111','U');
INSERT INTO Taken VALUES(2222222222,'CCC222','U');
INSERT INTO Taken VALUES(2222222222,'CCC444','U');

INSERT INTO WaitingList VALUES(3333333333,'CCC222',1);
INSERT INTO WaitingList VALUES(3333333333,'CCC333',1);
INSERT INTO WaitingList VALUES(2222222222,'CCC333',2);

-- end inserts.sql

-- start views.sql

-- BasicInformation(idnr, name, login, program, branch)
CREATE VIEW BasicInformation(idnr, name, login, program, branch) AS
	SELECT
		Students.idnr				AS idnr,
		Students.name				AS name,
		Students.login				AS login,
		Students.program			AS program,
		StudentBranch.branch		AS branch
	FROM Students LEFT JOIN StudentBranch ON (Students.idnr=StudentBranch.student);

-- FinishedCourses(student, course, grade, credits)
CREATE VIEW FinishedCourses(student, course, grade, credits) AS
	SELECT DISTINCT
		st.idnr		AS student,
		cs.code		AS course,
		tkn.grade	AS grade,
		cs.credits	AS credits

	FROM
		Students	AS st,
		Courses		AS cs,
		Taken		AS tkn

	WHERE
		tkn.student = st.idnr AND tkn.course = cs.code AND
		(LOWER(tkn.grade) = 'u'
		OR tkn.grade = '3'
		OR tkn.grade = '4'
		OR tkn.grade = '5') -- Do this with checks when creating the tables instead
	;

-- PassedCourses(student, course, credits)
CREATE VIEW PassedCourses(student, course, credits) AS
	SELECT
		st.student		AS student,
		st.course		AS course,
		st.credits		AS credits

	FROM
		(SELECT DISTINCT *
		FROM FinishedCourses) as st
	WHERE
		LOWER(st.grade) <> 'u';

-- Registrations helper table
CREATE VIEW RegistrationsHelper(Student, name, status) AS
	(SELECT student, course, 'registered' FROM Registered)
	UNION
	(SELECT student, course, 'waiting' FROM WaitingList);

-- Registrations(student, course, status)
CREATE VIEW Registrations(student, course, status) AS
	SELECT * FROM RegistrationsHelper;

-- ALL MANDATORY COURSES FOR ALL STUDENTS

CREATE VIEW StudentsMandatoryProgramCourses AS
	SELECT
		BasicInformation.idnr	AS student,
		BasicInformation.program,
		MandatoryProgram.course
	FROM BasicInformation JOIN mandatoryprogram ON (BasicInformation.program = mandatoryprogram.program);

CREATE VIEW StudentsMandatoryBranchCourses AS
	SELECT
		BasicInformation.idnr	AS student,
		BasicInformation.branch,
		MandatoryBranch.course
	FROM BasicInformation JOIN mandatorybranch ON (BasicInformation.branch = mandatorybranch.branch AND
	 BasicInformation.program = mandatorybranch.program);

-- Courses both from branches and programs
CREATE VIEW StudentsMandatoryCourses AS
	(SELECT
		student,
		course
	FROM StudentsMandatoryProgramCourses)
	UNION
	(SELECT
		student,
		course
	FROM StudentsMandatoryBranchCourses)
	;


CREATE VIEW StudentsMandatoryGrades AS
	SELECT
		*
	FROM
		StudentsMandatoryCourses LEFT JOIN taken USING (student,course);


CREATE VIEW UnreadMandatory(student, course) AS (
    SELECT
            smg.student,
            smg.course
    FROM
       studentsmandatorygrades AS smg

	WHERE
		smg.grade IS NULL OR UPPER(smg.grade) = 'U'
);


-- All passed courses with their classification (Helper view)
CREATE VIEW PassedClassifiedCourses AS
	SELECT * FROM PassedCourses JOIN Classified USING(course);



CREATE VIEW StudentsClassfied AS (
	SELECT
		pcc.idnr AS student,
		pcc.program,
		pcc.course,
		pcc.credits,
		pcc.classification

	FROM
		(Students LEFT JOIN PassedClassifiedCourses ON (Students.idnr = PassedClassifiedCourses.student)) AS pcc

);


--CREATE VIEW test AS
--	SELECT
--		*
--	FROM
--		Students LEFT JOIN StudentsClassfied ON (StudentsClassfied.classification = 'math') -- OR
												 --StudentsClassfied.classification = 'research' OR
												 --StudentsClassfied.classification = 'seminar')

--;


CREATE VIEW MathCredits AS
	WITH MathCreditsHelper AS (
		(SELECT
			student,
			CASE WHEN sc.classification = 'math'
				THEN credits
				ELSE 0
			END 		AS credits

		FROM
			StudentsClassfied as sc
		)
)
	SELECT
		student,
		SUM(credits) AS credits
	FROM
		MathCreditsHelper
	GROUP BY student
;

CREATE VIEW ResearchCredits AS
WITH ResearchCreditsHelper AS (
		(SELECT
			student,
			CASE WHEN sc.classification = 'research'
				THEN credits
				ELSE 0
			END 		AS credits

		FROM
			StudentsClassfied as sc
		)
)
	SELECT
		student,
		SUM(credits) AS credits
	FROM
		ResearchCreditsHelper
	GROUP BY student
;


CREATE VIEW SeminarCourses AS
WITH SeminarCreditsHelper AS (
		(SELECT
			student,
			CASE WHEN sc.classification = 'seminar'
				THEN 1
				ELSE 0
			END 		AS count

		FROM
			StudentsClassfied as sc
		)
)
	SELECT
		student,
		SUM(count) AS courses
	FROM
		SeminarCreditsHelper
	GROUP BY student
;


CREATE VIEW TotalCredits AS
WITH TotalCreditsHelper AS (
	SELECT
		fc.student				AS student,
		COUNT(fc.course)		AS course,
		SUM(fc.credits)			AS credits

	FROM
		FinishedCourses AS fc
	WHERE
		fc.grade <> 'U'
	GROUP BY
		student
)	SELECT
		students.idnr	AS student,
		COALESCE(TotalCreditsHelper.credits,0)		AS credits,
		COALESCE(TotalCreditsHelper.course, 0)		AS courses
	FROM
		students LEFT JOIN TotalCreditsHelper ON (students.idnr = TotalCreditsHelper.student);


CREATE VIEW StudentsRecommendedBranches AS
	WITH StudentProgramBranch AS (
		SELECT
			idnr	as student,
			program,
			branch
		FROM
			BasicInformation
	)
	SELECT
		StudentProgramBranch.student,
		StudentProgramBranch.branch,
		recommendedbranch.course
	FROM
		StudentProgramBranch JOIN recommendedbranch ON(
			StudentProgramBranch.branch = recommendedbranch.branch AND
			StudentProgramBranch.program = recommendedbranch.program
		);

CREATE VIEW StudentsRecommendedGrades AS
	SELECT DISTINCT *
	FROM
		StudentsRecommendedBranches LEFT JOIN FinishedCourses USING(course, student);


CREATE VIEW StudentsRecommendedCredits AS
	SELECT
		srg.idnr		AS student,
		CASE WHEN UPPER(srg.grade)='U' OR (srg.grade) IS NULL
				THEN 0
			ELSE srg.credits
		END
	FROM
		(StudentsRecommendedGrades RIGHT JOIN students ON (StudentsRecommendedGrades.student = students.idnr)) AS srg;


----- QUALIFIED

CREATE VIEW StudentsPassedMandatory AS
	SELECT
		student,
		BOOL_AND(CASE WHEN UPPER(grade)='U' OR grade IS NULL
		 		THEN False
			ELSE True
			END) AS passed
	FROM
		studentsmandatorygrades
	GROUP BY
		student
	;

CREATE VIEW qualified AS (
	SELECT DISTINCT
		src.student		   	AS student,
		BOOL_OR(spm.passed AND
	    COALESCE(src.credits, 0) >= 10  AND
		COALESCE(mcs.credits, 0) >= 20  AND
		COALESCE(rcs.credits, 0) >= 10  AND
		COALESCE(scs.courses, 0) >= 1)		AS qualified

	FROM
		StudentsRecommendedCredits AS src,
		MathCredits AS mcs,
		ResearchCredits AS rcs,
		SeminarCourses AS scs,
		StudentsPassedMandatory AS spm

	GROUP BY src.student
);




CREATE VIEW PathToGraduation (student, totalCredits, mandatoryLeft, mathCredits, researchCredits, seminarCourses, qualified) AS
	WITH help AS (
		SELECT
			Students.idnr					AS student,
			UnreadMandatory.course			AS course
		FROM
			Students LEFT JOIN UnreadMandatory ON (Students.idnr = UnreadMandatory.student)
	)
	SELECT DISTINCT
		st.idnr, -- Student national ID number
		total.credits,	-- Student number of credits
		COUNT(unread.course), -- Unread mandatory courses
		COALESCE(SUM(CASE WHEN class.classification = 'math' THEN class.credits END), 0), -- Math credits
		COALESCE(SUM(CASE WHEN class.classification = 'research' THEN class.credits END), 0), -- Research credits
		COALESCE(COUNT(CASE WHEN class.classification = 'seminar'  THEN class.credits END), 0), -- Number of seminar courses attended
		BOOL_OR(qualified.qualified)
	FROM
		Students				AS st,
		help					AS unread,
		TotalCredits			AS total,
		StudentsClassfied 		AS class,
		qualified
	WHERE
		st.idnr	= total.student AND
		st.idnr = unread.student AND
		st.idnr = class.student AND
		st.idnr = qualified.student

	GROUP BY st.idnr, total.credits

	ORDER BY total.credits 	ASC,
			 st.idnr		DESC
;

-- end views.sql