-- =====================================================================
-- RSVP Event Handler: queries.sql
-- Every SQL command the app uses, grouped by the Milestone 2 screens (S1 to S9).
-- Run after schema.sql, data.sql and advanced.sql.
--
-- The examples use real values from our sample data. In the PHP app, each value that
-- comes from the logged-in user or a form (IDs, names, dates) is passed in as a parameter.
--   - The logged-in user is Maya Patel (UserID 1), as in Milestone 2.
--   - "Now" is written as '2026-11-09 12:00:00'; the app passes the current date and time.
--
-- This file changes data (it signs up users, submits and cancels RSVPs, and so on).
-- To get back to the original sample data, drop rsvp_db and import schema.sql,
-- data.sql and advanced.sql again.
-- =====================================================================

USE rsvp_db;

-- =====================================================================
-- S1: Log in / Sign up
-- =====================================================================

-- Log in: find the account by email. PHP then checks the typed password against PasswordHash.
SELECT UserID, FirstName, LastName, UserType, PasswordHash
FROM USER
WHERE Email = 'mp4821@nyu.edu';

-- Sign up: the email and the NetID must not already be used (errors on S1c).
SELECT COUNT(*) AS EmailTaken FROM USER WHERE Email = 'kp1234@nyu.edu';
SELECT COUNT(*) AS NetIDTaken FROM USER WHERE NetID = 'kp1234';

-- Sign up: create an NYU account (it gets UserID 51). PasswordHash is made by PHP.
INSERT INTO USER (UserType, NetID, FirstName, LastName, Email, PasswordHash)
VALUES ('NYU', 'kp1234', 'Kim', 'Pham', 'kp1234@nyu.edu',
        '$2y$10$SV5j/1.dhN4CHuj.GMmXt.p.MvBCIg4py1PCaiTfTFMkN1dtV7HK6');

-- Sign up: save the phone numbers from "+ Add another phone" (zero or more).
INSERT INTO USER_PHONE (UserID, PhoneNumber)
VALUES (51, '(212) 555-0101'),
       (51, '(917) 555-0102');

-- Sign up: create an external account, which has no NetID (it gets UserID 52).
INSERT INTO USER (UserType, NetID, FirstName, LastName, Email, PasswordHash)
VALUES ('External', NULL, 'Jules', 'Martin', 'jules.martin@gmail.com',
        '$2y$10$SV5j/1.dhN4CHuj.GMmXt.p.MvBCIg4py1PCaiTfTFMkN1dtV7HK6');

-- =====================================================================
-- S2: Browse Events
-- =====================================================================

-- Upcoming events Maya is allowed to see: public events, NYU-only events (she is an NYU user),
-- and invite-only events she was invited to and has not declined.
-- Shows spots left (our function) and her own RSVP status if she has one.
SELECT e.EventID, e.Title, o.OrgName, e.StartTime, e.EndTime,
       v.VenueName, v.Building, v.Floor, v.RoomNumber,
       e.RequiresApproval, e.Visibility,
       e.Capacity - fn_spots_taken(e.EventID) AS SpotsLeft,
       my.RSVPStatus AS MyStatus
FROM EVENT e
INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
INNER JOIN VENUE v ON v.VenueID = e.VenueID
LEFT JOIN (SELECT EventID, RSVPStatus FROM RSVP WHERE UserID = 1) my ON my.EventID = e.EventID
WHERE e.EventStatus = 'Scheduled'
  AND e.StartTime > '2026-11-09 12:00:00'
  AND (e.Visibility = 'Public'
       OR (e.Visibility = 'NYU-only' AND (SELECT UserType FROM USER WHERE UserID = 1) = 'NYU')
       OR (e.Visibility = 'Invite-only' AND e.EventID IN (SELECT EventID FROM INVITATION
                                                          WHERE InviteeID = 1 AND InvitationStatus <> 'Declined')))
ORDER BY e.StartTime;

-- Search bar ("night") and "Sort by: Spots left". (Shortened to public events here;
-- the app keeps the same visibility conditions as the query above.)
SELECT e.EventID, e.Title, o.OrgName, e.StartTime, v.VenueName,
       e.Capacity - fn_spots_taken(e.EventID) AS SpotsLeft
FROM EVENT e
INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
INNER JOIN VENUE v ON v.VenueID = e.VenueID
WHERE e.EventStatus = 'Scheduled'
  AND e.StartTime > '2026-11-09 12:00:00'
  AND e.Visibility = 'Public'
  AND (e.Title LIKE '%night%' OR e.Description LIKE '%night%')
ORDER BY SpotsLeft DESC;

-- Filters: the app adds a line for each filter the user picks.
-- Here: organization = Poetry Society, building = Kimmel Center, date = December 10, 2026.
SELECT e.EventID, e.Title, o.OrgName, e.StartTime, v.VenueName
FROM EVENT e
INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
INNER JOIN VENUE v ON v.VenueID = e.VenueID
WHERE e.EventStatus = 'Scheduled'
  AND e.StartTime > '2026-11-09 12:00:00'
  AND e.OrgID = 1
  AND v.Building = 'Kimmel Center'
  AND e.StartTime >= '2026-12-10 00:00:00' AND e.StartTime < '2026-12-11 00:00:00'
ORDER BY e.StartTime;

-- Filter dropdowns.
SELECT OrgID, OrgName FROM ORGANIZATION ORDER BY OrgName;
SELECT DISTINCT Building FROM VENUE ORDER BY Building;

-- =====================================================================
-- S3: Event Details and RSVP Form (Winter Poetry Slam, EventID 18)
-- =====================================================================

-- Event information, rules and capacity bar.
SELECT e.EventID, e.Title, e.Description, o.OrgName AS HostedBy,
       e.StartTime, e.EndTime, e.RSVPDeadline,
       v.VenueName, v.Building, v.Floor, v.RoomNumber,
       e.RequiresApproval, e.Visibility, e.MaxPlusOnes, e.EventStatus,
       e.Capacity, fn_spots_taken(e.EventID) AS SpotsTaken
FROM EVENT e
INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
INNER JOIN VENUE v ON v.VenueID = e.VenueID
WHERE e.EventID = 18;

-- Ticket types with spots left in each (confirmed RSVPs plus their guests, from our function).
SELECT TypeName, Description, TypeCapacity,
       TypeCapacity - fn_type_spots_taken(EventID, TypeName) AS SpotsLeft
FROM TICKET_TYPE
WHERE EventID = 18
ORDER BY TypeCapacity DESC;

-- Questions from the organizer.
SELECT QuestionID, QuestionText, IsRequired
FROM RSVP_QUESTION
WHERE EventID = 18
ORDER BY QuestionID;

-- Already RSVPed card: does Maya already have an RSVP for this event? (none yet)
SELECT r.RSVPID, r.TypeName, r.SubmittedAt, r.RSVPStatus, a.Reason AS DeclineReason
FROM RSVP r
LEFT JOIN APPROVAL a ON a.RSVPID = r.RSVPID
WHERE r.EventID = 18 AND r.UserID = 1;

-- Submit the RSVP. The app picks the status first: Pending if the event needs approval,
-- Confirmed if there is space for Maya and her guest, otherwise Waitlisted.
-- trg_rsvp_before_insert checks the rules again before the row is saved. (New RSVPID 310.)
INSERT INTO RSVP (EventID, TypeName, UserID, SubmittedAt, RSVPStatus)
VALUES (18, 'General', 1, '2026-11-09 12:00:00', 'Confirmed');

-- Save the plus-ones from "+ Add guest".
INSERT INTO PLUS_ONE (RSVPID, GuestNo, GuestName, GuestEmail)
VALUES (310, 1, 'Alex Kim', 'alex@gmail.com');

-- Save the answer to the required question "How did you hear about this event?" (QuestionID 11).
INSERT INTO RSVP_ANSWER (RSVPID, QuestionID, AnswerText)
VALUES (310, 11, 'Club newsletter');

-- The card now shows the RSVP and its guests.
SELECT r.RSVPID, r.TypeName, r.SubmittedAt, r.RSVPStatus, p.GuestName
FROM RSVP r
LEFT JOIN PLUS_ONE p ON p.RSVPID = r.RSVPID
WHERE r.EventID = 18 AND r.UserID = 1;

-- Invite-only events: was the user invited? (Ethan Moore, UserID 7, to Poets' Circle Dinner, EventID 17)
SELECT InvitationStatus
FROM INVITATION
WHERE EventID = 17 AND InviteeID = 7;

-- Ethan RSVPs through his invitation (new RSVPID 311) and answers the required question.
-- trg_rsvp_after_insert then sets his invitation to Accepted
-- (Milestone 2: accepting an invitation means RSVPing).
INSERT INTO RSVP (EventID, TypeName, UserID, SubmittedAt, RSVPStatus)
VALUES (17, 'General', 7, '2026-11-09 12:05:00', 'Confirmed');

INSERT INTO RSVP_ANSWER (RSVPID, QuestionID, AnswerText)
VALUES (311, 9, 'None');

SELECT InvitationStatus
FROM INVITATION
WHERE EventID = 17 AND InviteeID = 7;

-- =====================================================================
-- S4: My RSVPs (RSVPs and Invitations)
-- =====================================================================

-- RSVPs tab, Upcoming: Maya's RSVPs for events that have not started, with the number of
-- guests, the event status (to show "cancelled by the organizer") and any decline reason.
SELECT r.RSVPID, e.EventID, e.Title, o.OrgName, e.StartTime, v.VenueName, r.TypeName,
       COUNT(p.GuestNo) AS Guests, r.SubmittedAt, r.RSVPStatus, e.EventStatus,
       a.Reason AS DeclineReason
FROM RSVP r
INNER JOIN EVENT e ON e.EventID = r.EventID
INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
INNER JOIN VENUE v ON v.VenueID = e.VenueID
LEFT JOIN PLUS_ONE p ON p.RSVPID = r.RSVPID
LEFT JOIN APPROVAL a ON a.RSVPID = r.RSVPID
WHERE r.UserID = 1 AND e.StartTime >= '2026-11-09 12:00:00'
GROUP BY r.RSVPID, e.EventID, e.Title, o.OrgName, e.StartTime, v.VenueName, r.TypeName,
         r.SubmittedAt, r.RSVPStatus, e.EventStatus, a.Reason
ORDER BY e.StartTime;

-- Guest names shown on each RSVP row.
SELECT p.RSVPID, p.GuestNo, p.GuestName
FROM PLUS_ONE p
INNER JOIN RSVP r ON r.RSVPID = p.RSVPID
WHERE r.UserID = 1
ORDER BY p.RSVPID, p.GuestNo;

-- Waitlist position: Maya's Diwali Gala RSVP (RSVPID 147) is number 3.
SELECT COUNT(*) AS WaitlistPosition
FROM RSVP
WHERE EventID = 9 AND RSVPStatus = 'Waitlisted'
  AND SubmittedAt <= (SELECT SubmittedAt FROM RSVP WHERE RSVPID = 147);

-- RSVPs tab, Past: past events and whether Maya checked in.
SELECT r.RSVPID, e.Title, o.OrgName, e.StartTime, v.VenueName, r.TypeName,
       r.RSVPStatus, c.CheckedInAt
FROM RSVP r
INNER JOIN EVENT e ON e.EventID = r.EventID
INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
INNER JOIN VENUE v ON v.VenueID = e.VenueID
LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
WHERE r.UserID = 1 AND e.StartTime < '2026-11-09 12:00:00'
ORDER BY e.StartTime DESC;

-- Summary chips: active upcoming RSVPs by status.
SELECT r.RSVPStatus, COUNT(*) AS RSVPs
FROM RSVP r
INNER JOIN EVENT e ON e.EventID = r.EventID
WHERE r.UserID = 1 AND e.StartTime >= '2026-11-09 12:00:00'
  AND r.RSVPStatus IN ('Pending', 'Confirmed', 'Waitlisted')
GROUP BY r.RSVPStatus
ORDER BY r.RSVPStatus;

-- Cancel RSVP (after the pop-up). The procedure cancels it and, if it was confirmed,
-- moves people up from the waitlist.
CALL sp_cancel_rsvp(310, 1);

SELECT RSVPID, RSVPStatus FROM RSVP WHERE RSVPID = 310;

-- Invitations tab.
SELECT i.InvitationID, e.EventID, e.Title, o.OrgName, e.StartTime, v.VenueName,
       u.FirstName AS InvitedByFirstName, u.LastName AS InvitedByLastName,
       i.SentAt, i.InvitationStatus
FROM INVITATION i
INNER JOIN EVENT e ON e.EventID = i.EventID
INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
INNER JOIN VENUE v ON v.VenueID = e.VenueID
INNER JOIN USER u ON u.UserID = i.InvitedBy
WHERE i.InviteeID = 1
ORDER BY i.SentAt DESC;

-- Number on the Invitations tab: invitations that still need an answer.
SELECT COUNT(*) AS InvitationsToAnswer
FROM INVITATION i
INNER JOIN EVENT e ON e.EventID = i.EventID
WHERE i.InviteeID = 1 AND i.InvitationStatus = 'Sent' AND e.EventStatus = 'Scheduled';

-- Decline an invitation (Alumni Networking Night, InvitationID 23).
UPDATE INVITATION
SET InvitationStatus = 'Declined'
WHERE InvitationID = 23 AND InviteeID = 1;

-- =====================================================================
-- S5: Profile and My Organizations
-- =====================================================================

-- My details and phone numbers.
SELECT UserID, FirstName, LastName, Email, UserType, NetID
FROM USER
WHERE UserID = 1;

SELECT PhoneNumber FROM USER_PHONE WHERE UserID = 1 ORDER BY PhoneNumber;

-- Save changes (the UNIQUE constraint on Email stops a duplicate email).
UPDATE USER
SET FirstName = 'Maya', LastName = 'Patel', Email = 'mp4821@nyu.edu'
WHERE UserID = 1;

-- Add and remove a phone number.
INSERT INTO USER_PHONE (UserID, PhoneNumber) VALUES (1, '(646) 555-0177');
DELETE FROM USER_PHONE WHERE UserID = 1 AND PhoneNumber = '(646) 555-0177';

-- My Organizations, with role and join date.
SELECT o.OrgID, o.OrgName, o.Description, m.Role, m.JoinedDate
FROM ORG_MEMBERSHIP m
INNER JOIN ORGANIZATION o ON o.OrgID = m.OrgID
WHERE m.UserID = 1
ORDER BY m.Role DESC, o.OrgName;

-- Number of officers in each of Maya's organizations.
-- The Leave button is disabled where she is the only officer.
SELECT OrgID, COUNT(*) AS Officers
FROM ORG_MEMBERSHIP
WHERE Role = 'Officer'
  AND OrgID IN (SELECT OrgID FROM ORG_MEMBERSHIP WHERE UserID = 1)
GROUP BY OrgID
ORDER BY OrgID;

-- Leave an organization (Women in Computing, OrgID 3).
DELETE FROM ORG_MEMBERSHIP WHERE UserID = 1 AND OrgID = 3;

-- Create organization pop-up: check the name is free, create it (OrgID 13),
-- and add Maya as its first officer.
SELECT COUNT(*) AS NameTaken FROM ORGANIZATION WHERE OrgName = 'NYU Hiking Club';

INSERT INTO ORGANIZATION (OrgName, ContactEmail, Description)
VALUES ('NYU Hiking Club', 'hiking.club@nyu.edu', 'Weekend hikes in the Hudson Valley for all levels.');

INSERT INTO ORG_MEMBERSHIP (UserID, OrgID, Role, JoinedDate)
VALUES (1, 13, 'Officer', '2026-11-09');

-- =====================================================================
-- S6: Organization Dashboard (officers only) - Poetry Society, OrgID 1
-- =====================================================================

-- Only officers can open the page: Maya's role in this organization.
SELECT Role FROM ORG_MEMBERSHIP WHERE UserID = 1 AND OrgID = 1;

-- Events whose end time has passed become Completed (run when the dashboard loads).
UPDATE EVENT
SET EventStatus = 'Completed'
WHERE EventStatus = 'Scheduled' AND EndTime < '2026-11-09 12:00:00';

-- Organization header.
SELECT OrgName, Description, ContactEmail FROM ORGANIZATION WHERE OrgID = 1;

-- Edit details pop-up (the UNIQUE constraint on OrgName stops a duplicate name).
UPDATE ORGANIZATION
SET OrgName = 'Poetry Society',
    ContactEmail = 'poetry.society@nyu.edu',
    Description = 'Open mics, workshops and readings for anyone who loves writing.'
WHERE OrgID = 1;

-- Events tab: every event with spots taken.
SELECT e.EventID, e.Title, e.StartTime, v.VenueName, e.RequiresApproval, e.Visibility,
       e.EventStatus, e.Capacity, fn_spots_taken(e.EventID) AS SpotsTaken
FROM EVENT e
INNER JOIN VENUE v ON v.VenueID = e.VenueID
WHERE e.OrgID = 1
ORDER BY e.StartTime;

-- Events tab: pending and waitlisted counts for each event ("3 to review").
SELECT r.EventID, r.RSVPStatus, COUNT(*) AS RSVPs
FROM RSVP r
INNER JOIN EVENT e ON e.EventID = r.EventID
WHERE e.OrgID = 1 AND r.RSVPStatus IN ('Pending', 'Waitlisted')
GROUP BY r.EventID, r.RSVPStatus
ORDER BY r.EventID;

-- Events tab: checked in out of confirmed RSVPs ("26 of 30 RSVPs checked in").
SELECT r.EventID, COUNT(c.CheckInID) AS CheckedIn, COUNT(r.RSVPID) AS ConfirmedRSVPs
FROM RSVP r
INNER JOIN EVENT e ON e.EventID = r.EventID
LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
WHERE e.OrgID = 1 AND r.RSVPStatus = 'Confirmed'
GROUP BY r.EventID
ORDER BY r.EventID;

-- Members tab.
SELECT u.UserID, u.FirstName, u.LastName, u.NetID, u.Email, u.UserType, m.Role, m.JoinedDate
FROM ORG_MEMBERSHIP m
INNER JOIN USER u ON u.UserID = m.UserID
WHERE m.OrgID = 1
ORDER BY m.Role DESC, m.JoinedDate;

-- Add member pop-up: find the user by email or NetID, and check they are not a member yet.
SELECT UserID, FirstName, LastName, NetID, Email
FROM USER
WHERE Email = 'ak9012' OR NetID = 'ak9012';

SELECT COUNT(*) AS AlreadyMember FROM ORG_MEMBERSHIP WHERE UserID = 6 AND OrgID = 1;

-- Add Ava Kim as a member.
INSERT INTO ORG_MEMBERSHIP (UserID, OrgID, Role, JoinedDate)
VALUES (6, 1, 'Member', '2026-11-09');

-- Make officer / Make member (Jordan Lee).
UPDATE ORG_MEMBERSHIP SET Role = 'Officer' WHERE UserID = 2 AND OrgID = 1;
UPDATE ORG_MEMBERSHIP SET Role = 'Member' WHERE UserID = 2 AND OrgID = 1;

-- Before removing or demoting an officer, the app checks there is more than one officer.
SELECT COUNT(*) AS Officers FROM ORG_MEMBERSHIP WHERE OrgID = 1 AND Role = 'Officer';

-- Remove a member (their RSVPs are not affected).
DELETE FROM ORG_MEMBERSHIP WHERE UserID = 6 AND OrgID = 1;

-- =====================================================================
-- S7: Create / Edit Event (officers only)
-- =====================================================================

-- Venue dropdown with each venue's maximum capacity.
SELECT VenueID, VenueName, Building, Floor, RoomNumber, MaxCapacity
FROM VENUE
ORDER BY Building, VenueName;

-- Create event (it gets EventID 26). The app has already checked that the capacity
-- is not more than the venue's MaxCapacity; the CHECK constraints check the times.
INSERT INTO EVENT (OrgID, VenueID, Title, Description, StartTime, EndTime, Capacity,
                   RequiresApproval, Visibility, MaxPlusOnes, RSVPDeadline, EventStatus)
VALUES (1, 4, 'Spring Poetry Reading', 'Members read new work from the winter break.',
        '2027-03-18 19:00:00', '2027-03-18 21:00:00', 60,
        FALSE, 'Public', 1, '2027-03-17 23:59:00', 'Scheduled');

-- Ticket types and questions for the new event (QuestionIDs 13 and 14).
INSERT INTO TICKET_TYPE (EventID, TypeName, TypeCapacity, Description)
VALUES (26, 'General', 50, 'Open seating'),
       (26, 'Reader', 10, 'Read one piece on stage');

INSERT INTO RSVP_QUESTION (EventID, QuestionText, IsRequired)
VALUES (26, 'What will you read?', FALSE),
       (26, 'How did you hear about this event?', TRUE);

-- Running total of ticket capacity under the ticket types (must not go over 60).
SELECT SUM(TypeCapacity) AS TicketTotal FROM TICKET_TYPE WHERE EventID = 26;

-- Edit mode (Winter Poetry Slam, EventID 18): load the event and count its RSVPs.
-- If there are RSVPs, approval and visibility are locked.
SELECT * FROM EVENT WHERE EventID = 18;

SELECT COUNT(*) AS RSVPCount FROM RSVP WHERE EventID = 18;

-- Ticket types with how many RSVPs use each one (names are locked once used).
SELECT t.TypeName, t.TypeCapacity, t.Description, COUNT(r.RSVPID) AS RSVPs
FROM TICKET_TYPE t
LEFT JOIN RSVP r ON r.EventID = t.EventID AND r.TypeName = t.TypeName
WHERE t.EventID = 18
GROUP BY t.TypeName, t.TypeCapacity, t.Description
ORDER BY t.TypeName;

-- Questions with how many answers each one has (locked once answered).
SELECT q.QuestionID, q.QuestionText, q.IsRequired, COUNT(a.RSVPID) AS Answers
FROM RSVP_QUESTION q
LEFT JOIN RSVP_ANSWER a ON a.QuestionID = q.QuestionID
WHERE q.EventID = 18
GROUP BY q.QuestionID, q.QuestionText, q.IsRequired
ORDER BY q.QuestionID;

-- Save changes.
UPDATE EVENT
SET Description = 'Our end-of-semester slam. Sign up to perform a poem (3 minutes max) or come to listen and vote. Hot chocolate provided.',
    Capacity = 70
WHERE EventID = 18;

UPDATE TICKET_TYPE
SET TypeCapacity = 60, Description = 'Open seating, vote for your favorite poems'
WHERE EventID = 18 AND TypeName = 'General';

-- Add a question to an event that already has RSVPs (it cannot be required then).
INSERT INTO RSVP_QUESTION (EventID, QuestionText, IsRequired)
VALUES (18, 'Any song requests for the break?', FALSE);

-- Remove a ticket type or question nobody has used yet.
-- (The foreign keys from RSVP and RSVP_ANSWER block this once one has been used.)
DELETE FROM TICKET_TYPE WHERE EventID = 26 AND TypeName = 'Reader';
DELETE FROM RSVP_QUESTION WHERE QuestionID = 13;

-- Cancel this event. trg_event_after_update then cancels all of its RSVPs.
UPDATE EVENT SET EventStatus = 'Cancelled' WHERE EventID = 26;

-- =====================================================================
-- S8: Manage Event (officers only) - Haiku Writing Workshop, EventID 16
-- =====================================================================

-- Event header and the Spots taken card.
SELECT e.Title, e.StartTime, e.EndTime, e.RSVPDeadline, v.VenueName, v.Building, v.Floor, v.RoomNumber,
       e.RequiresApproval, e.Visibility, e.EventStatus, e.Capacity,
       fn_spots_taken(e.EventID) AS SpotsTaken
FROM EVENT e
INNER JOIN VENUE v ON v.VenueID = e.VenueID
WHERE e.EventID = 16;

-- Ticket types card ("General 20 of 20").
SELECT TypeName, fn_type_spots_taken(EventID, TypeName) AS SpotsTaken, TypeCapacity
FROM TICKET_TYPE
WHERE EventID = 16;

-- Status filter chips with counts (also gives the Pending and Waitlisted cards).
SELECT RSVPStatus, COUNT(*) AS RSVPs
FROM RSVP
WHERE EventID = 16
GROUP BY RSVPStatus
ORDER BY RSVPStatus;

-- RSVP table, Pending filter, with each person's answers (one row per answer).
SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.TypeName, r.SubmittedAt,
       q.QuestionText, a.AnswerText, r.RSVPStatus
FROM RSVP r
INNER JOIN USER u ON u.UserID = r.UserID
LEFT JOIN RSVP_ANSWER a ON a.RSVPID = r.RSVPID
LEFT JOIN RSVP_QUESTION q ON q.QuestionID = a.QuestionID
WHERE r.EventID = 16 AND r.RSVPStatus = 'Pending'
ORDER BY r.SubmittedAt;

-- Number of guests on each RSVP.
SELECT r.RSVPID, COUNT(p.GuestNo) AS Guests
FROM RSVP r
LEFT JOIN PLUS_ONE p ON p.RSVPID = r.RSVPID
WHERE r.EventID = 16
GROUP BY r.RSVPID
ORDER BY r.RSVPID;

-- Search box (name or NetID starting with "Eth").
SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.RSVPStatus
FROM RSVP r
INNER JOIN USER u ON u.UserID = r.UserID
WHERE r.EventID = 16
  AND (u.FirstName LIKE 'Eth%' OR u.LastName LIKE 'Eth%' OR u.NetID LIKE 'Eth%');

-- Approve Ethan Moore (RSVPID 253). The event is full (spots open = 0) and others are
-- already waiting, so the app saves the approval and puts him on the waitlist.
SELECT Capacity - fn_spots_taken(EventID) AS SpotsOpen FROM EVENT WHERE EventID = 16;

INSERT INTO APPROVAL (RSVPID, ReviewedBy, Decision, DecidedAt, Reason)
VALUES (253, 1, 'Approved', '2026-11-09 12:10:00', NULL);

UPDATE RSVP SET RSVPStatus = 'Waitlisted' WHERE RSVPID = 253;

-- Decline Lina Haddad (RSVPID 254) with a reason (S8b).
INSERT INTO APPROVAL (RSVPID, ReviewedBy, Decision, DecidedAt, Reason)
VALUES (254, 1, 'Declined', '2026-11-09 12:11:00',
        'This workshop is for students in the Creative Writing minor this term.');

UPDATE RSVP SET RSVPStatus = 'Declined' WHERE RSVPID = 254;

-- Waitlist tab, in submission order (the row number is the position: Ethan is 3rd).
SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.TypeName, r.SubmittedAt
FROM RSVP r
INNER JOIN USER u ON u.UserID = r.UserID
WHERE r.EventID = 16 AND r.RSVPStatus = 'Waitlisted'
ORDER BY r.SubmittedAt;

-- Invitations tab (Poets' Circle Dinner, EventID 17).
-- Find users to invite by name, email or NetID, leaving out anyone already invited.
SELECT UserID, FirstName, LastName, NetID, Email
FROM USER
WHERE (FirstName LIKE '%Grace%' OR LastName LIKE '%Grace%' OR Email LIKE '%Grace%' OR NetID LIKE 'Grace%')
  AND UserID NOT IN (SELECT InviteeID FROM INVITATION WHERE EventID = 17);

-- Send invitations (S8d: Grace Liu and Daniel Cho).
INSERT INTO INVITATION (EventID, InviteeID, InvitedBy, SentAt, InvitationStatus)
VALUES (17, 14, 1, '2026-11-09 12:15:00', 'Sent'),
       (17, 13, 1, '2026-11-09 12:15:00', 'Sent');

-- Sent invitations table (USER appears twice: once for the invitee, once for the officer).
SELECT u.FirstName, u.LastName, u.NetID,
       b.FirstName AS InvitedByFirstName, b.LastName AS InvitedByLastName,
       i.SentAt, i.InvitationStatus
FROM INVITATION i
INNER JOIN USER u ON u.UserID = i.InviteeID
INNER JOIN USER b ON b.UserID = i.InvitedBy
WHERE i.EventID = 17
ORDER BY i.SentAt;

-- Summary line ("10 sent: 6 accepted, 3 waiting, 1 declined").
SELECT InvitationStatus, COUNT(*) AS Invitations
FROM INVITATION
WHERE EventID = 17
GROUP BY InvitationStatus
ORDER BY InvitationStatus;

-- Attendance tab (Fall Reading Night, EventID 3). The rate is rounded to 87%.
SELECT COUNT(r.RSVPID) AS ConfirmedRSVPs,
       COUNT(c.CheckInID) AS CheckedIn,
       COUNT(r.RSVPID) - COUNT(c.CheckInID) AS NoShows,
       ROUND(100 * COUNT(c.CheckInID) / COUNT(r.RSVPID)) AS AttendanceRate
FROM RSVP r
LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
WHERE r.EventID = 3 AND r.RSVPStatus = 'Confirmed';

-- Guests of checked-in RSVPs (they come in with the person who brought them).
SELECT COUNT(*) AS GuestsCheckedIn
FROM PLUS_ONE p
INNER JOIN CHECK_IN c ON c.RSVPID = p.RSVPID
INNER JOIN RSVP r ON r.RSVPID = p.RSVPID
WHERE r.EventID = 3;

-- Attendance by ticket type.
SELECT r.TypeName, COUNT(r.RSVPID) AS Confirmed, COUNT(c.CheckInID) AS CheckedIn
FROM RSVP r
LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
WHERE r.EventID = 3 AND r.RSVPStatus = 'Confirmed'
GROUP BY r.TypeName
ORDER BY r.TypeName;

-- No-shows list.
SELECT u.FirstName, u.LastName, r.TypeName
FROM RSVP r
INNER JOIN USER u ON u.UserID = r.UserID
LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
WHERE r.EventID = 3 AND r.RSVPStatus = 'Confirmed' AND c.CheckInID IS NULL
ORDER BY r.TypeName, u.LastName;

-- =====================================================================
-- S9: Check-in (officers only, phone) - Open Mic Night, EventID 8
-- =====================================================================

-- Live counter: checked in out of confirmed RSVPs. Milestone 2 showed this screen partway
-- through the event ("15 of 24 checked in"); with all of our sample check-ins it returns 20 of 24.
SELECT COUNT(c.CheckInID) AS CheckedIn, COUNT(r.RSVPID) AS ConfirmedRSVPs
FROM RSVP r
LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
WHERE r.EventID = 8 AND r.RSVPStatus = 'Confirmed';

-- Attendee list ("All" chip): confirmed RSVPs with ticket, guest and check-in time, sorted by last name.
SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.TypeName, p.GuestName, c.CheckedInAt
FROM RSVP r
INNER JOIN USER u ON u.UserID = r.UserID
LEFT JOIN PLUS_ONE p ON p.RSVPID = r.RSVPID
LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
WHERE r.EventID = 8 AND r.RSVPStatus = 'Confirmed'
ORDER BY u.LastName, u.FirstName;

-- "Not checked in" chip.
SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.TypeName
FROM RSVP r
INNER JOIN USER u ON u.UserID = r.UserID
LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
WHERE r.EventID = 8 AND r.RSVPStatus = 'Confirmed' AND c.CheckInID IS NULL
ORDER BY u.LastName, u.FirstName;

-- Search by name or NetID. It also finds people whose RSVP is not confirmed, so the app
-- can show "Not confirmed. Do not admit." (S9c: Riley Chen's RSVP was cancelled).
SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.RSVPStatus
FROM RSVP r
INNER JOIN USER u ON u.UserID = r.UserID
WHERE r.EventID = 8
  AND (u.FirstName LIKE 'Riley%' OR u.LastName LIKE 'Riley%' OR u.NetID LIKE 'Riley%');

-- Check in Sara Kowalski (RSVPID 111), who has not checked in yet.
-- trg_check_in_before_insert makes sure the RSVP is confirmed.
INSERT INTO CHECK_IN (RSVPID, CheckedInBy, CheckedInAt)
VALUES (111, 1, '2026-11-05 20:25:00');

-- Undo (within a few seconds of checking in).
DELETE FROM CHECK_IN WHERE RSVPID = 111;
