-- BasicInformation(idnr, name, login, program, branch)
CREATE VIEW BasicInformation(idnr, name, login, program, branch) AS
	SELECT
		Students.idnr			AS idnr,
		Students.name			AS name,
		Students.login			AS login,
		Students.program		AS program,
		StudentBranches.branch	AS branch
	FROM Students LEFT JOIN StudentBranches ON (Students.idnr=StudentBranches.student);

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
	SELECT 
		studentbranches.student,
		studentbranches.branch,
		recommendedbranch.course 
	FROM 
		studentbranches JOIN recommendedbranch ON(
			studentbranches.branch = recommendedbranch.branch AND
			studentbranches.program = recommendedbranch.program
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