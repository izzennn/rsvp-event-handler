-- =====================================================================
-- RSVP Event Handler: schema.sql
-- CS-UY 3083, Milestone 3
-- Creates the database and all 14 tables from Milestone 1.
-- Change from Milestone 1: USER has a new PasswordHash column (Milestone 2, section 4.11).
-- Run order: schema.sql -> data.sql -> advanced.sql -> queries.sql
-- To rebuild from scratch, drop rsvp_db first (phpMyAdmin: Operations -> Drop the database).
-- =====================================================================

CREATE DATABASE rsvp_db;
USE rsvp_db;

-- ---------------------------------------------------------------------
-- 1. VENUE
-- ---------------------------------------------------------------------
CREATE TABLE VENUE (
    VenueID      INT AUTO_INCREMENT,
    VenueName    VARCHAR(100) NOT NULL,
    Building     VARCHAR(100) NOT NULL,
    Floor        INT          NOT NULL,
    RoomNumber   VARCHAR(20)  NULL,
    MaxCapacity  INT          NOT NULL,
    PRIMARY KEY (VenueID),
    CONSTRAINT chk_venue_capacity CHECK (MaxCapacity > 0)
);

-- ---------------------------------------------------------------------
-- 2. ORGANIZATION
-- ---------------------------------------------------------------------
CREATE TABLE ORGANIZATION (
    OrgID         INT AUTO_INCREMENT,
    OrgName       VARCHAR(100) NOT NULL,
    ContactEmail  VARCHAR(100) NOT NULL,
    Description   VARCHAR(500) NULL,
    PRIMARY KEY (OrgID),
    UNIQUE (OrgName)
);

-- ---------------------------------------------------------------------
-- 3. USER
-- ---------------------------------------------------------------------
CREATE TABLE USER (
    UserID        INT AUTO_INCREMENT,
    UserType      VARCHAR(10)  NOT NULL,
    NetID         VARCHAR(15)  NULL,
    FirstName     VARCHAR(50)  NOT NULL,
    LastName      VARCHAR(50)  NOT NULL,
    Email         VARCHAR(100) NOT NULL,
    PasswordHash  VARCHAR(255) NOT NULL,
    PRIMARY KEY (UserID),
    UNIQUE (NetID),
    UNIQUE (Email),
    CONSTRAINT chk_user_type CHECK (UserType IN ('NYU', 'External')),
    -- NYU users must have a NetID; external users cannot have one
    CONSTRAINT chk_user_netid CHECK (
        (UserType = 'NYU' AND NetID IS NOT NULL) OR
        (UserType = 'External' AND NetID IS NULL)
    )
);

-- ---------------------------------------------------------------------
-- 4. USER_PHONE (multivalued attribute PhoneNumber)
-- ---------------------------------------------------------------------
CREATE TABLE USER_PHONE (
    UserID       INT         NOT NULL,
    PhoneNumber  VARCHAR(20) NOT NULL,
    PRIMARY KEY (UserID, PhoneNumber),
    FOREIGN KEY (UserID) REFERENCES USER(UserID)
);

-- ---------------------------------------------------------------------
-- 5. ORG_MEMBERSHIP (M:N relationship Member of)
-- ---------------------------------------------------------------------
CREATE TABLE ORG_MEMBERSHIP (
    UserID      INT         NOT NULL,
    OrgID       INT         NOT NULL,
    Role        VARCHAR(10) NOT NULL,
    JoinedDate  DATE        NOT NULL,
    PRIMARY KEY (UserID, OrgID),
    FOREIGN KEY (UserID) REFERENCES USER(UserID),
    FOREIGN KEY (OrgID) REFERENCES ORGANIZATION(OrgID),
    CONSTRAINT chk_membership_role CHECK (Role IN ('Officer', 'Member'))
);

-- ---------------------------------------------------------------------
-- 6. EVENT
-- ---------------------------------------------------------------------
CREATE TABLE EVENT (
    EventID           INT AUTO_INCREMENT,
    OrgID             INT          NOT NULL,
    VenueID           INT          NOT NULL,
    Title             VARCHAR(150) NOT NULL,
    Description       VARCHAR(1000) NULL,
    StartTime         DATETIME     NOT NULL,
    EndTime           DATETIME     NOT NULL,
    Capacity          INT          NOT NULL,
    RequiresApproval  BOOLEAN      NOT NULL DEFAULT FALSE,
    Visibility        VARCHAR(15)  NOT NULL DEFAULT 'Public',
    MaxPlusOnes       INT          NOT NULL DEFAULT 0,
    RSVPDeadline      DATETIME     NOT NULL,
    EventStatus       VARCHAR(10)  NOT NULL DEFAULT 'Scheduled',
    PRIMARY KEY (EventID),
    FOREIGN KEY (OrgID) REFERENCES ORGANIZATION(OrgID),
    FOREIGN KEY (VenueID) REFERENCES VENUE(VenueID),
    CONSTRAINT chk_event_times     CHECK (EndTime > StartTime),
    CONSTRAINT chk_event_deadline  CHECK (RSVPDeadline < StartTime),
    CONSTRAINT chk_event_capacity  CHECK (Capacity > 0),
    CONSTRAINT chk_event_plusones  CHECK (MaxPlusOnes >= 0),
    CONSTRAINT chk_event_visibility CHECK (Visibility IN ('Public', 'NYU-only', 'Invite-only')),
    CONSTRAINT chk_event_status    CHECK (EventStatus IN ('Scheduled', 'Cancelled', 'Completed'))
);

-- ---------------------------------------------------------------------
-- 7. TICKET_TYPE (weak entity, owner EVENT)
-- ---------------------------------------------------------------------
CREATE TABLE TICKET_TYPE (
    EventID       INT          NOT NULL,
    TypeName      VARCHAR(50)  NOT NULL,
    TypeCapacity  INT          NOT NULL,
    Description   VARCHAR(255) NULL,
    PRIMARY KEY (EventID, TypeName),
    FOREIGN KEY (EventID) REFERENCES EVENT(EventID),
    CONSTRAINT chk_type_capacity CHECK (TypeCapacity > 0)
);

-- ---------------------------------------------------------------------
-- 8. RSVP_QUESTION
-- ---------------------------------------------------------------------
CREATE TABLE RSVP_QUESTION (
    QuestionID    INT AUTO_INCREMENT,
    EventID       INT          NOT NULL,
    QuestionText  VARCHAR(255) NOT NULL,
    IsRequired    BOOLEAN      NOT NULL DEFAULT FALSE,
    PRIMARY KEY (QuestionID),
    FOREIGN KEY (EventID) REFERENCES EVENT(EventID)
);

-- ---------------------------------------------------------------------
-- 9. RSVP
-- (EventID, TypeName) is one composite foreign key to TICKET_TYPE.
-- Because of this foreign key, a ticket type cannot be deleted once someone has RSVPed to it.
-- ---------------------------------------------------------------------
CREATE TABLE RSVP (
    RSVPID       INT AUTO_INCREMENT,
    EventID      INT          NOT NULL,
    TypeName     VARCHAR(50)  NOT NULL,
    UserID       INT          NOT NULL,
    SubmittedAt  DATETIME     NOT NULL,
    RSVPStatus   VARCHAR(12)  NOT NULL,
    PRIMARY KEY (RSVPID),
    UNIQUE (EventID, UserID),
    FOREIGN KEY (EventID, TypeName) REFERENCES TICKET_TYPE(EventID, TypeName),
    FOREIGN KEY (UserID) REFERENCES USER(UserID),
    CONSTRAINT chk_rsvp_status CHECK (RSVPStatus IN ('Pending', 'Confirmed', 'Waitlisted', 'Declined', 'Cancelled'))
);

-- ---------------------------------------------------------------------
-- 10. PLUS_ONE (weak entity, owner RSVP)
-- ---------------------------------------------------------------------
CREATE TABLE PLUS_ONE (
    RSVPID      INT          NOT NULL,
    GuestNo     INT          NOT NULL,
    GuestName   VARCHAR(100) NOT NULL,
    GuestEmail  VARCHAR(100) NULL,
    PRIMARY KEY (RSVPID, GuestNo),
    FOREIGN KEY (RSVPID) REFERENCES RSVP(RSVPID),
    CONSTRAINT chk_guest_no CHECK (GuestNo > 0)
);

-- ---------------------------------------------------------------------
-- 11. RSVP_ANSWER (M:N relationship Answers)
-- Because of the QuestionID foreign key, a question cannot be deleted once it has answers.
-- ---------------------------------------------------------------------
CREATE TABLE RSVP_ANSWER (
    RSVPID      INT          NOT NULL,
    QuestionID  INT          NOT NULL,
    AnswerText  VARCHAR(500) NOT NULL,
    PRIMARY KEY (RSVPID, QuestionID),
    FOREIGN KEY (RSVPID) REFERENCES RSVP(RSVPID),
    FOREIGN KEY (QuestionID) REFERENCES RSVP_QUESTION(QuestionID)
);

-- ---------------------------------------------------------------------
-- 12. APPROVAL (1:1 with RSVP)
-- ---------------------------------------------------------------------
CREATE TABLE APPROVAL (
    ApprovalID  INT AUTO_INCREMENT,
    RSVPID      INT          NOT NULL,
    ReviewedBy  INT          NOT NULL,
    Decision    VARCHAR(10)  NOT NULL,
    DecidedAt   DATETIME     NOT NULL,
    Reason      VARCHAR(255) NULL,
    PRIMARY KEY (ApprovalID),
    UNIQUE (RSVPID),
    FOREIGN KEY (RSVPID) REFERENCES RSVP(RSVPID),
    FOREIGN KEY (ReviewedBy) REFERENCES USER(UserID),
    CONSTRAINT chk_approval_decision CHECK (Decision IN ('Approved', 'Declined'))
);

-- ---------------------------------------------------------------------
-- 13. CHECK_IN (1:1 with RSVP)
-- ---------------------------------------------------------------------
CREATE TABLE CHECK_IN (
    CheckInID    INT AUTO_INCREMENT,
    RSVPID       INT      NOT NULL,
    CheckedInBy  INT      NOT NULL,
    CheckedInAt  DATETIME NOT NULL,
    PRIMARY KEY (CheckInID),
    UNIQUE (RSVPID),
    FOREIGN KEY (RSVPID) REFERENCES RSVP(RSVPID),
    FOREIGN KEY (CheckedInBy) REFERENCES USER(UserID)
);

-- ---------------------------------------------------------------------
-- 14. INVITATION
-- ---------------------------------------------------------------------
CREATE TABLE INVITATION (
    InvitationID      INT AUTO_INCREMENT,
    EventID           INT         NOT NULL,
    InviteeID         INT         NOT NULL,
    InvitedBy         INT         NOT NULL,
    SentAt            DATETIME    NOT NULL,
    InvitationStatus  VARCHAR(10) NOT NULL DEFAULT 'Sent',
    PRIMARY KEY (InvitationID),
    UNIQUE (EventID, InviteeID),
    FOREIGN KEY (EventID) REFERENCES EVENT(EventID),
    FOREIGN KEY (InviteeID) REFERENCES USER(UserID),
    FOREIGN KEY (InvitedBy) REFERENCES USER(UserID),
    CONSTRAINT chk_invitation_status CHECK (InvitationStatus IN ('Sent', 'Accepted', 'Declined'))
);
