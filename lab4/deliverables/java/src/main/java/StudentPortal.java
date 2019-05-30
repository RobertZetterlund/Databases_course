/* This is the driving engine of the program. It parses the command-line
 * arguments and calls the appropriate methods in the other classes.
 *
 * You should edit this file in two ways:
 * 1) Insert your database username and password in the proper places.
 * 2) Implement the three functions getInformation, registerStudent
 *    and unregisterStudent.
 */
import java.sql.*; // JDBC stuff.
import java.util.Properties;
import java.io.*;  // Reading user input.

public class StudentPortal {
    /* TODO Here you should put your database name, username and password */
    static final String DATABASE = "";
    static final String USERNAME = "";
    static final String PASSWORD = "";

    /* Print command usage.
     * /!\ you don't need to change this function! */
    public static void usage() {
        System.out.println("Usage:");
        System.out.println("    i[nformation]");
        System.out.println("    r[egister] <course>");
        System.out.println("    u[nregister] <course>");
        System.out.println("    q[uit]");
    }

    /* main: parses the input commands.
     * /!\ You don't need to change this function! */
    public static void main(String[] args) throws Exception {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", USERNAME);
        props.setProperty("password", PASSWORD);

        // Try with resource (requires Java 7) to close connection automatically
        try (Connection conn = DriverManager.getConnection(DATABASE, props)) {
            // In Eclipse. System.console() returns null due to a bug (https://bugs.eclipse.org/bugs/show_bug.cgi?id=122429)
            // In that case, use the following line instead:
            BufferedReader console = new BufferedReader(new InputStreamReader(System.in));

            String student;
            if (args.length > 0)
                student = args[0]; // This is the identifier for the student.
            else {
                System.out.println("Input student idnr:");
                // student = "1111111111"; // For quick test runs
                //  student = "2222222222"; // For quick test runs
                // student = "4444444444"; // For quick test runs
                student = console.readLine();
            }

            usage();
            System.out.println("Welcome!");
            while (true) {
                System.out.print("? > ");
                String mode = console.readLine();
                String[] cmd = mode.split(" +");
                cmd[0] = cmd[0].toLowerCase();
                if ("information".startsWith(cmd[0]) && cmd.length == 1) {
                    /* Information mode */
                    getInformation(conn, student);
                } else if ("register".startsWith(cmd[0]) && cmd.length == 2) {
                    /* Register student mode */
                    registerStudent(conn, student, cmd[1]);
                } else if ("unregister".startsWith(cmd[0]) && cmd.length == 2) {
                    /* Unregister student mode */
                    unregisterStudent(conn, student, cmd[1]);
                } else if ("quit".startsWith(cmd[0])) {
                    break;
                } else usage();
            }
            System.out.println("Goodbye!");
        } catch (SQLException e) {
            System.err.println(e);
            System.exit(2);
        }
    }

    /* Given a student identification number, this function should print
     * - the name of the student, the students national identification number
     *   and their issued login name (something similar to a CID)
     * - the programme and branch (if any) that the student is following.
     * - the courses that the student has read, along with the grade.
     * - the courses that the student is registered to. (queue position if the student is waiting for the course)
     * - the number of mandatory courses that the student has yet to read.
     * - whether or not the student fulfills the requirements for graduation
     */
    static void getInformation(Connection conn, String student) throws SQLException {
        long studentid = Long.valueOf(student);
        // Student basic information
        PreparedStatement statement = conn.prepareStatement("SELECT * FROM BasicInformation WHERE idnr=?");
        statement.setLong(1, studentid);

        ResultSet studentInfo = statement.executeQuery();

        if (studentInfo.next()) {
            printBasicInformation(studentInfo);
        }

        // Courses
        // Taken
        statement = conn.prepareStatement("SELECT * FROM finishedcourses JOIN courses on finishedcourses.course=courses.code WHERE student=?");
        statement.setLong(1, studentid);

        ResultSet finished = statement.executeQuery();

        // Registered
        statement = conn.prepareStatement("SELECT * FROM (Registrations LEFT JOIN Courses ON Registrations.course=Courses.code) as tmp " +
            "LEFT JOIN CourseQueuePositions ON CourseQueuePositions.course=tmp.course AND CourseQueuePositions.student=tmp.student " +
                "WHERE tmp.student=?");
        statement.setLong(1, studentid);

        ResultSet registered = statement.executeQuery();


        // Mandatory
        statement = conn.prepareStatement("SELECT mandatoryLeft, qualified FROM PathToGraduation WHERE student = ?");
        statement.setLong(1, studentid);
        ResultSet mandatoryCourses = statement.executeQuery();


        // Print course information
        printFinishedCourses(finished);
        printRegisteredCourses(registered);
        printMandatoryCoursesLeft(mandatoryCourses);


        // Close connections
        studentInfo.close();
        finished.close();
        registered.close();
        mandatoryCourses.close();
        statement.close();
    }

    private static void printMandatoryCoursesLeft(ResultSet rs) throws SQLException {
        if (rs.next()) {
            System.out.println("Unread Mandatory Courses : " + rs.getString(1));
            System.out.println("Qualified: " + (rs.getString(2).equals("t") ? "Yes" : "No"));
        }
    }

    private static void printFinishedCourses(ResultSet rs) throws SQLException {
        System.out.println("Read courses (name (code), credits: grade):");

        while(rs.next()) {
            System.out.println(rs.getString(6) + " ("
                    + rs.getString(5) + "), "
                    + rs.getString(7) + ": "
                    + rs.getString(3)
            );
        }
        System.out.println();
    }

    private static void printRegisteredCourses(ResultSet rs) throws SQLException {
        System.out.println("Registered courses (name (code), status):");

        while (rs.next()) {
            String maybeRegistered = rs.getString(3);
            System.out.println(rs.getString(5) + " ("
                    + rs.getString(4) + "): "
                    + maybeRegistered +
                    ("registered".equals(maybeRegistered) ? "" : " pos: " + rs.getString(9))
            );
        }
        System.out.println();
    }


    private static void printBasicInformation(ResultSet rs) throws SQLException {
        // Idnr
        System.out.println("Information for student " + rs.getString(1));
        // Delimiter
        System.out.println("----------------------------------");
        // Name
        System.out.println("Name: " + rs.getString(2));
        // Student id
        System.out.println("Student ID: " + rs.getString(3));
        // Program
        System.out.println("Program " + rs.getString(4));
        // Branch
        String maybeBranch = rs.getString(5);
        System.out.println("Branch: " +
                ("null".equals(maybeBranch) ? maybeBranch : "none")
        );
        System.out.println();
    }

    /* Register: Given a student id number and a course code, this function
     * should try to register the student for that course.
     */

    static void registerStudent(Connection conn, String student, String course)
            throws SQLException {
        PreparedStatement st = conn.prepareStatement("INSERT INTO registrations VALUES (?, ?);");
        st.setLong(1, Long.valueOf(student));
        st.setString(2, course);
        try {
            int success = st.executeUpdate();
            if(success > 0) {
                // 1 or more rows where inserted
                System.out.println("Registration successful");
            } else {
                // No rows where inserted (fail)
                System.out.println("Registration failed");
            }
        }
        catch (SQLException e) {
            System.out.println("Registration failed");
        }
        st.close();
    }

    /* Unregister: Given a student id number and a course code, this function
     * should unregister the student from that course.
     */
    static void unregisterStudent(Connection conn, String student, String course) throws SQLException {
        PreparedStatement st = conn.prepareStatement("DELETE FROM registrations WHERE student = ? AND course = ?;");
        st.setLong(1, Long.valueOf(student));
        st.setString(2, course);
        try {
            int success = st.executeUpdate();
            if(success > 0) {
                // 1 or more rows where inserted
                System.out.println("Unregistration successful");
            } else {
                // No rows where inserted (fail)
                System.out.println("Unregistration failed");
            }
        }
        catch (SQLException e) {
            System.out.println("Registration failed");
        }
        st.close();
    }
}
