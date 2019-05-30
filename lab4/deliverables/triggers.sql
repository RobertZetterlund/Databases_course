---- LAB 3 ----

CREATE VIEW CourseQueuePositions(course,student,place) AS
	SELECT
		wl.course,
		wl.student,
		wl.position
	FROM
		WaitingList AS wl
;

CREATE FUNCTION student_register() RETURNS trigger AS $student_register$
    DECLARE
    alreadyRegistrations   BOOLEAN; 
    totalSeats          INT;
	takenSeats          INT;
    passedPreqCourses   INT;
    amountPreqCourses   INT;
	BEGIN
        -- Check if already in Registrations table
        SELECT
            (EXISTS (SELECT
                *
            FROM
                Registrations
            WHERE
                (Registrations.student = NEW.student) AND
                (Registrations.course = NEW.course))
            )
        INTO alreadyRegistrations;

        IF(alreadyRegistrations)
            THEN
                RAISE EXCEPTION 'Student % already Registrations on course %', NEW.student, NEW.course;
        END IF;

        -- Check that student meets all prerequisites
        SELECT
            COUNT(course)
        FROM
          --  IS NULL ANY (
            -- Prerequisite courses   
            (SELECT 
                course
            FROM
                (SELECT
                    Prerequisites.prerequisite AS preq
                FROM
                    Prerequisites
                WHERE
                    NEW.course = Prerequisites.course
                ) AS p
                JOIN 
            -- Passed courses 
                (SELECT
                    PassedCourses.course AS course
                FROM
                    PassedCourses
                WHERE
                    NEW.student = PassedCourses.student
                ) AS pc
                ON (p.preq = pc.course)
            ) AS xd
        INTO passedPreqCourses;

        SELECT
            COUNT(prerequisite)
        FROM 
            prerequisites
        WHERE
            NEW.course = prerequisites.course
        INTO amountPreqCourses;

        -- Check if student does NOT meet requirements
        IF(passedPreqCourses <> amountPreqCourses)
            THEN
       		    RAISE EXCEPTION 'Student % not eligible for course %', NEW.student, NEW.course;
        END IF;

		-- Check if there are any seats left on the course
		
		-- Get total seats for a limited course
		SELECT 
			LimitedCourses.seats
		INTO totalSeats
			FROM LimitedCourses
			WHERE NEW.course = LimitedCourses.code
		;

		-- Get number of students taking a course
		SELECT 
			COUNT(Registrations.course)
		INTO takenSeats
			FROM Registrations
			WHERE NEW.course = Registrations.course
		;

		IF(takenSeats >= totalSeats) THEN
			-- Limited course is full, put student on waiting list
            INSERT INTO WaitingList VALUES(NEW.student, NEW.course, nextNumber(NEW.course));
		ELSIF(totalSeats IS NULL)
            -- Course is not limited, just register the student already
            THEN
            INSERT INTO Registered VALUES(NEW.student, NEW.course);
        END IF;

       	RETURN NEW;
    END;
$student_register$ LANGUAGE plpgsql;

CREATE TRIGGER student_register INSTEAD OF INSERT ON Registrations
    FOR EACH ROW EXECUTE FUNCTION student_register();





--- Trigger(s) on Registrations

CREATE FUNCTION move_to_registered() RETURNS trigger AS $move_to_registered$
    DECLARE
    number_of_students  INTEGER;
    number_of_seats     INTEGER;
    waiting_students    INTEGER;
    i INTEGER := 0;
    BEGIN
    -- Count number of students taking course
    SELECT
        COALESCE(COUNT(student), 0)
    FROM
        Registered
    WHERE
        OLD.course = Registered.course
    INTO number_of_students;

    -- Get max amount of seats
    SELECT
        COALESCE(seats, 0)
    FROM
        LimitedCourses
    WHERE
        OLD.course = LimitedCourses.code
    INTO number_of_seats;

    -- Get number of waiting students
    SELECT
        COALESCE(COUNT(course), 0)
    FROM
        WaitingList
    WHERE
        OLD.course = WaitingList.course
    INTO waiting_students;

    DELETE FROM Registered WHERE OLD.student = Registered.student AND OLD.course = Registered.course;

    -- Declare vairables if any
    IF(OLD.status = 'registered')
        THEN
            LOOP
            EXIT WHEN ((number_of_students + i) > number_of_seats OR (waiting_students - i) <= 0);
                PERFORM "register_waiting"(OLD.course); -- MOVE FROM WAITINGLIST
                SELECT i + 1 INTO i;
            END LOOP;
    ELSE
        DELETE FROM WaitingList WHERE OLD.student = WaitingList.student AND OLD.course = WaitingList.course;
    END IF;

    RETURN OLD;
    END;

$move_to_registered$ LANGUAGE plpgsql;

CREATE FUNCTION register_waiting(CHAR(6))
    RETURNS void AS $$
    DECLARE
        studentid   NUMERIC(10);
    BEGIN
    -- Kolla i waitinglist, flytta studenten med
    SELECT
        student
    FROM 
        WaitingList
    WHERE
        (WaitingList.course = $1) AND (WaitingList.position = 1)
    INTO studentid;

    DELETE FROM WaitingList WHERE WaitingList.student = studentid AND WaitingList.course = $1;
    INSERT INTO Registered VALUES(studentid, $1);

    END
$$ LANGUAGE plpgsql;

CREATE TRIGGER move_to_registered INSTEAD OF DELETE ON Registrations
    FOR EACH ROW EXECUTE FUNCTION move_to_registered();


--- Trigger on WaitingList
CREATE FUNCTION bump_positions_wl() RETURNS trigger AS $bump_positions_wl$
    BEGIN    
        UPDATE WaitingList SET position = position -1
            WHERE OLD.course = course AND OLD.position < position;
        RETURN OLD;
    END;
$bump_positions_wl$ LANGUAGE plpgsql;

CREATE TRIGGER bump_positions_wl AFTER DELETE ON WaitingList
    FOR EACH ROW EXECUTE FUNCTION bump_positions_wl();


--- Some nice functions ---


CREATE FUNCTION nextNumber(CHAR(6))
    RETURNS integer AS $$
BEGIN
    RETURN (SELECT
        COUNT(*)+1
    FROM
        WaitingList
    WHERE
        course=$1
    );
END
$$ LANGUAGE plpgsql;