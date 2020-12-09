/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT DISTINCT name
FROM Facilities
WHERE membercost >0;

/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT( DISTINCT name )
FROM Facilities
WHERE membercost =0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
HAVING membercost < monthlymaintenance * 0.2;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT * 
FROM Facilities
WHERE facid IN (1, 5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
	CASE WHEN monthlymaintenance >100 THEN "expensive"
	ELSE "cheap" END AS maintenancelabel
FROM Facilities

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT surname, firstname
FROM Members
WHERE joindate IN (SELECT MAX(joindate) 
                   FROM Members);

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT f.name,
	CASE 
		WHEN m.surname = 'GUEST' THEN m.surname
		ELSE CONCAT( m.surname, ", ", m.firstname )
	END AS member_name
FROM `Bookings` b
	INNER JOIN `Members` m 
	ON b.memid = m.memid
	INNER JOIN `Facilities` AS f 
	ON b.facid = f.facid
WHERE b.facid IN ( 0, 1 )
	AND m.surname != 'GUEST'
ORDER BY member_name, b.facid

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */
SELECT name, 
         CONCAT( firstname,  ' ', surname ) AS membername, 
         CASE 
             WHEN b.memid = 0 THEN guestcost * slots
             ELSE membercost * slots
         END AS cost
    FROM Members AS m
         INNER JOIN Bookings AS b 
         ON m.memid = b.memid

         INNER JOIN Facilities AS f 
         ON b.facid = f.facid
   WHERE starttime BETWEEN  '2012-09-14 00:00:00' AND '2012-09-14 23:59:59'
     AND CASE WHEN b.memid = 0
         THEN guestcost * slots
         ELSE membercost * slots
         END > 30
ORDER BY cost DESC;


/* Q9: This time, produce the same result as in Q8, but using a subquery. */
 SELECT c.name, 
         CONCAT(firstname, ' ', surname) AS membername, 
         c.cost 
    FROM Members AS m
         INNER JOIN (SELECT name,
                            memid,
                            CASE
                                WHEN memid = 0 THEN guestcost * slots
                                ELSE membercost * slots
                            END AS cost
                       FROM Bookings AS b
                            INNER JOIN Facilities AS f
                            ON b.facid = f.facid
                      WHERE starttime BETWEEN  '2012-09-14 00:00:00' AND '2012-09-14 23:59:59') AS c 
         ON m.memid = c.memid
WHERE c.cost > 30
ORDER BY c.cost DESC; 

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT subq.Facility_name, 
		SUM( subq.revenues ) AS total_revenue
	FROM (

			SELECT Facilities.name AS Facility_name,
				CASE 
					WHEN Bookings.memid <>0
					THEN Facilities.membercost * Bookings.slots
					WHEN Bookings.memid =0
					THEN Facilities.guestcost * Bookings.slots
				END AS revenues
			FROM `Members`
				INNER JOIN `Bookings` ON Bookings.memid = Members.memid
				INNER JOIN `Facilities` ON Facilities.facid = Bookings.facid) AS subq
GROUP BY subq.Facility_name
HAVING total_revenue <1000

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
SELECT Members.surname AS member_surname, Members.firstname AS member_firstname, R.surname AS recommender_surname, R.firstname AS recommender_firstname
FROM Members
INNER JOIN `Members` AS R ON Members.recommendedby = R.memid
WHERE Members.memid <>0
ORDER BY member_surname


/* Q12: Find the facilities with their usage by member, but not guests */
SELECT CONCAT( subq.firstname, ' ', subq.surname ) AS Full_name, subq.Facility_name, subq.total_usage
	FROM (
		SELECT Facilities.name AS Facility_name, Members.firstname, Members.surname,
			CASE 
				WHEN Members.memid <>0 THEN (Members.memid * Bookings.slots)
			END AS total_usage
		FROM `Members`
			INNER JOIN `Bookings` ON Bookings.memid = Members.memid
			INNER JOIN `Facilities` ON Facilities.facid = Bookings.facid
		WHERE Members.memid <> 0) AS subq
GROUP BY Full_name, subq.Facility_name
ORDER BY Full_name ASC

/* Q13: Find the facilities usage by month, but not guests */
SELECT subq.Facility_name, subq.Month, 
		SUM( subq.total_member_use ) AS Total_Member_Usage
	FROM (
			SELECT Facilities.name AS Facility_name, MONTHNAME( Bookings.starttime ) AS MONTH ,
				CASE 
					WHEN Members.memid <>0 THEN (Members.memid * Bookings.slots)
				END AS total_member_use
			FROM `Members`
				INNER JOIN `Bookings` ON Bookings.memid = Members.memid
				INNER JOIN `Facilities` ON Facilities.facid = Bookings.facid
			WHERE Members.memid <>0) AS subq

GROUP BY subq.Facility_name,MONTH
ORDER BY subq.Facility_name DESC
