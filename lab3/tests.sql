-- Trigger tests

-- Register the student for an unrestricted course
-- EXPECTED OUTCOME: Student 1111111111 should be listed as 'registered' for the unlimited course CCC555.
-- ' ----- TEST 1 ----- \n'
SELECT * FROM registrations;

-- 'Trying to register a student for an unlimited course .. \n'

INSERT INTO registrations VALUES (1111111111, 'CCC555');

SELECT * FROM registrations;

DELETE FROM registrations WHERE (student = 1111111111 AND course = 'CCC555');


-- Register the same student for the same course again
-- EXPECTED OUTCOME: Student 1111111111 should only be listed once as 'registered' for the unlimited course CCC555.
-- ' ----- TEST 2 ----- \n'

-- 'Trying to register the same student for the same unrestricted course .. \n'

INSERT INTO registrations VALUES (1111111111, 'CCC555');
SELECT * FROM registrations;


-- Register a student to a limited course
-- EXPECTED OUTCOME: Student 4444444444 should be listed as 'waiting' for the limited course CCC333.

-- ' ----- TEST 3 ----- \n'

SELECT * FROM registrations;

-- 'Trying to register student 4444444444 into limited course CCC333 .. \n'

INSERT INTO registrations VALUES (4444444444, 'CCC333');
--  '\n'
SELECT * FROM registrations;
--  '\n'


-- Unregistered from limited course
-- EXPECTED OUTCOME: Student 1111111111 should be unregistered from the unlimited course
 
--  ' ----- TEST 4 ----- \n'

SELECT * FROM registrations;
--  'Trying to Unregister student 1111111111 from limited course CCC222 without (with empty) waiting list.. \n'
DELETE FROM WaitingList WHERE (student = 3333333333 AND course = 'CCC222');
-- By removing student 3333333333 from waitinglist ccc222 we empty the waitinglist for course ccc222.


DELETE FROM registrations WHERE (student = 1111111111 AND course = 'CCC222');

SELECT * FROM registrations;

-- Register the student for a course that they don't 
-- have the prerequisites for, and show that 
-- the registration doesn't go through. 

-- EXPECTED OUTCOME: Student 2222222222 should not be listed as registered for course CCC555
--  ' ----- TEST 5 ----- \n'
SELECT * FROM registrations;

--  'Trying to register a student for a course they are not eligible for .. \n'

INSERT INTO registrations VALUES (2222222222, 'CCC555');
--  '\n'
SELECT * FROM registrations;
--  '\n'


-- Unregister and re-register the same student for 
-- the same restricted course, and show that 
-- the student is first removed and then ends up in 
-- the same position as before (last). 

-- EXPECTED OUTCOME: Student 3333333333 should after a deletion followed by an insertion end up with the same position in the waitinglist as
-- he/she started with on course CCC333 (2 // Last).
--  ' ----- TEST 6 ----- \n'
SELECT * FROM waitinglist;

--  'Trying to unregister and re-register a student .. \n'

DELETE FROM registrations WHERE student = 4444444444;
--  '\n'
SELECT * FROM waitinglist;
--  '\n'
INSERT INTO registrations VALUES (4444444444, 'CCC333');
--  '\n'
SELECT * FROM waitinglist;
--  '\n'


-- Unregister a student from an unlimited course --
-- EXPECTED OUTCOME: Student 1111111111 should be not be in resulting table.
--  ' ----- TEST 7 ----- \n'

SELECT * FROM registrations;
--  'Trying to unregister a student from an unlimited course .. \n'
DELETE FROM registrations WHERE student = 1111111111 AND course = 'CCC555';
--  '\n'
SELECT * FROM registrations;
--  '\n'

-- Unregister a (registered) student from a limited course with waiting list

-- EXPECTED OUTCOME: Student 1111111111 should be registered and students 2222222222 and 3333333333
-- should be registered for the limited course CCC333.
--  ' ----- TEST 8 ----- \n'

SELECT * FROM registrations;
--  'Trying to unregister a student from a limited course with waiting list .. \n'
DELETE FROM registrations WHERE student = 1111111111 AND course = 'CCC333';
--  '\n'
SELECT * FROM registrations;
--  '\n'

-- Unregister a student from an overfull limited course with waiting list --

-- EXPECTED OUTCOME: Student 4444444444 should still be 'waiting' for course CCC222,
-- since CCC222 only has one seat.
--  ' ----- TEST 9 ----- \n'
-- SETUP CODE
INSERT INTO registrations VALUES (4444444444, 'CCC222');
INSERT INTO registered VALUES(1111111111, 'CCC222');


SELECT * FROM registrations;
--  'Trying to unregister a student from an overfull limited course with waiting list .. \n'
DELETE FROM registrations WHERE student = 1111111111 AND course = 'CCC222';
--  '\n'
SELECT * FROM registrations;
--  '\n'