-- RSVP Event Handler (CS-UY 3083, Milestone 4)
-- Database-level security: roles, accounts and privileges (role-based access control).
-- Run as root AFTER rsvp_db_backup.sql, because the grants name our tables and columns.
-- Before running it on the server, copy it and replace every CHANGE_ME_... with a real password.
-- It can be run again at any time: it removes the old accounts and roles first.

-- Remove the accounts and roles if they already exist
DROP USER IF EXISTS 'rsvp_member'@'localhost', 'rsvp_officer'@'localhost';
DROP USER IF EXISTS 'hamza'@'localhost', 'izen'@'localhost', 'rania'@'localhost', 'kashish'@'localhost';
DROP ROLE IF EXISTS rsvp_member_role, rsvp_officer_role, rsvp_developer_role;

-- ===== Roles =====
CREATE ROLE rsvp_member_role;
CREATE ROLE rsvp_officer_role;
CREATE ROLE rsvp_developer_role;

-- ===== rsvp_member_role: what the member pages need (S1 to S5) =====
-- Read: every table except RSVP_ANSWER (members never see other people's answers)
GRANT SELECT ON rsvp_db.VENUE TO rsvp_member_role;
GRANT SELECT ON rsvp_db.ORGANIZATION TO rsvp_member_role;
GRANT SELECT ON rsvp_db.USER TO rsvp_member_role;
GRANT SELECT ON rsvp_db.USER_PHONE TO rsvp_member_role;
GRANT SELECT ON rsvp_db.ORG_MEMBERSHIP TO rsvp_member_role;
GRANT SELECT ON rsvp_db.EVENT TO rsvp_member_role;
GRANT SELECT ON rsvp_db.TICKET_TYPE TO rsvp_member_role;
GRANT SELECT ON rsvp_db.RSVP_QUESTION TO rsvp_member_role;
GRANT SELECT ON rsvp_db.RSVP TO rsvp_member_role;
GRANT SELECT ON rsvp_db.PLUS_ONE TO rsvp_member_role;
GRANT SELECT ON rsvp_db.APPROVAL TO rsvp_member_role;
GRANT SELECT ON rsvp_db.CHECK_IN TO rsvp_member_role;
GRANT SELECT ON rsvp_db.INVITATION TO rsvp_member_role;

-- S1 sign up: create the account and its phone numbers
GRANT INSERT ON rsvp_db.USER TO rsvp_member_role;
GRANT INSERT, DELETE ON rsvp_db.USER_PHONE TO rsvp_member_role;

-- S5 profile: only these three columns can be changed (not NetID, UserType or PasswordHash)
GRANT UPDATE (FirstName, LastName, Email) ON rsvp_db.USER TO rsvp_member_role;

-- S5: create an organization (and become its first officer), and leave an organization
GRANT INSERT ON rsvp_db.ORGANIZATION TO rsvp_member_role;
GRANT INSERT, DELETE ON rsvp_db.ORG_MEMBERSHIP TO rsvp_member_role;

-- S3 submit an RSVP with guests and answers (the triggers check the business rules)
GRANT INSERT ON rsvp_db.RSVP TO rsvp_member_role;
GRANT INSERT ON rsvp_db.PLUS_ONE TO rsvp_member_role;
GRANT INSERT ON rsvp_db.RSVP_ANSWER TO rsvp_member_role;

-- S4 decline an invitation: only the status column
GRANT UPDATE (InvitationStatus) ON rsvp_db.INVITATION TO rsvp_member_role;

-- Our functions and sp_cancel_rsvp (S4 cancel). Members have no UPDATE on RSVP,
-- so the procedure is the only way they can cancel.
-- Given on the whole database: a privilege on one routine is deleted when the routine is re-created.
GRANT EXECUTE ON rsvp_db.* TO rsvp_member_role;

-- ===== rsvp_officer_role: everything a member can do, plus S6 to S9 =====
GRANT rsvp_member_role TO rsvp_officer_role;

-- S6 organization details, member roles
GRANT UPDATE (OrgName, ContactEmail, Description) ON rsvp_db.ORGANIZATION TO rsvp_officer_role;
GRANT UPDATE (Role) ON rsvp_db.ORG_MEMBERSHIP TO rsvp_officer_role;

-- S7 create and edit events (EventID and OrgID can never be changed), ticket types and questions
GRANT INSERT ON rsvp_db.EVENT TO rsvp_officer_role;
GRANT UPDATE (VenueID, Title, Description, StartTime, EndTime, Capacity, RequiresApproval,
              Visibility, MaxPlusOnes, RSVPDeadline, EventStatus) ON rsvp_db.EVENT TO rsvp_officer_role;
GRANT INSERT, UPDATE, DELETE ON rsvp_db.TICKET_TYPE TO rsvp_officer_role;
GRANT INSERT, UPDATE, DELETE ON rsvp_db.RSVP_QUESTION TO rsvp_officer_role;

-- S8 read answers, approve or decline (only the status column of RSVP), send invitations
GRANT SELECT ON rsvp_db.RSVP_ANSWER TO rsvp_officer_role;
GRANT UPDATE (RSVPStatus) ON rsvp_db.RSVP TO rsvp_officer_role;
GRANT INSERT ON rsvp_db.APPROVAL TO rsvp_officer_role;
GRANT INSERT ON rsvp_db.INVITATION TO rsvp_officer_role;

-- S9 check in, and undo a check-in
GRANT INSERT, DELETE ON rsvp_db.CHECK_IN TO rsvp_officer_role;

-- ===== rsvp_developer_role: work with the data, but no DROP, ALTER, CREATE or GRANT =====
-- Password hashes are sensitive, so developers cannot read or change USER.PasswordHash.
GRANT SELECT (UserID, UserType, NetID, FirstName, LastName, Email) ON rsvp_db.USER TO rsvp_developer_role;
GRANT UPDATE (UserType, NetID, FirstName, LastName, Email) ON rsvp_db.USER TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.VENUE TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.ORGANIZATION TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.USER_PHONE TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.ORG_MEMBERSHIP TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.EVENT TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.TICKET_TYPE TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.RSVP_QUESTION TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.RSVP TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.PLUS_ONE TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.RSVP_ANSWER TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.APPROVAL TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.CHECK_IN TO rsvp_developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON rsvp_db.INVITATION TO rsvp_developer_role;
GRANT EXECUTE ON rsvp_db.* TO rsvp_developer_role;

-- ===== Accounts =====
-- Every account is @'localhost': nobody can log in to the database from outside the server.

-- The two accounts the app uses (member pages and officer pages)
CREATE USER 'rsvp_member'@'localhost' IDENTIFIED BY 'CHANGE_ME_member';
CREATE USER 'rsvp_officer'@'localhost' IDENTIFIED BY 'CHANGE_ME_officer';
GRANT rsvp_member_role TO 'rsvp_member'@'localhost';
GRANT rsvp_officer_role TO 'rsvp_officer'@'localhost';

-- Developers
CREATE USER 'izen'@'localhost' IDENTIFIED BY 'CHANGE_ME_izen';
CREATE USER 'rania'@'localhost' IDENTIFIED BY 'CHANGE_ME_rania';
CREATE USER 'kashish'@'localhost' IDENTIFIED BY 'CHANGE_ME_kashish';
GRANT rsvp_developer_role TO 'izen'@'localhost';
GRANT rsvp_developer_role TO 'rania'@'localhost';
GRANT rsvp_developer_role TO 'kashish'@'localhost';

-- Database admin: full control of rsvp_db only (no server-wide privileges)
CREATE USER 'hamza'@'localhost' IDENTIFIED BY 'CHANGE_ME_hamza';
GRANT ALL PRIVILEGES ON rsvp_db.* TO 'hamza'@'localhost' WITH GRANT OPTION;

-- A granted role is only active once it is the account's default role.
-- Without these lines every login gets "access denied" (error 1044).
SET DEFAULT ROLE rsvp_member_role FOR 'rsvp_member'@'localhost';
SET DEFAULT ROLE rsvp_officer_role FOR 'rsvp_officer'@'localhost';
SET DEFAULT ROLE rsvp_developer_role FOR 'izen'@'localhost';
SET DEFAULT ROLE rsvp_developer_role FOR 'rania'@'localhost';
SET DEFAULT ROLE rsvp_developer_role FOR 'kashish'@'localhost';

-- ===== Check the result =====
SHOW GRANTS FOR rsvp_member_role;
SHOW GRANTS FOR rsvp_officer_role;
SHOW GRANTS FOR rsvp_developer_role;
SHOW GRANTS FOR 'hamza'@'localhost';
