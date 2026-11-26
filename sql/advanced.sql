-- =====================================================================
-- RSVP Event Handler: advanced.sql
-- Advanced SQL that enforces the main Milestone 1 business rules.
-- Run after data.sql (see the note at the top of data.sql).
--
-- Advanced command types used in the project:
--   1. CHECK constraints  (in schema.sql: times, capacities, status values, NetID rule)
--   2. Functions          fn_spots_taken, fn_type_spots_taken
--   3. Triggers           trg_rsvp_before_insert, trg_rsvp_after_insert,
--                         trg_plus_one_before_insert, trg_event_after_update,
--                         trg_check_in_before_insert
--   4. Stored procedure   sp_cancel_rsvp
--
-- In phpMyAdmin, run this file from the Import tab so the DELIMITER lines work.
-- =====================================================================

USE rsvp_db;

DELIMITER $$

-- ---------------------------------------------------------------------
-- FUNCTION: spots taken at an event = confirmed RSVPs + their plus-ones
-- (business rule 8). Used for "spots left" on S2, S3, S6 and S8.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_spots_taken(p_event_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_rsvps INT;
    DECLARE v_guests INT;

    SELECT COUNT(*) INTO v_rsvps
    FROM RSVP
    WHERE EventID = p_event_id AND RSVPStatus = 'Confirmed';

    SELECT COUNT(*) INTO v_guests
    FROM PLUS_ONE p
    INNER JOIN RSVP r ON r.RSVPID = p.RSVPID
    WHERE r.EventID = p_event_id AND r.RSVPStatus = 'Confirmed';

    RETURN v_rsvps + v_guests;
END$$

-- ---------------------------------------------------------------------
-- FUNCTION: spots taken in one ticket type = confirmed RSVPs with that type
-- + their plus-ones, since guests use the same ticket type (business rule 9).
-- Used for "General, 14 of 50 left" on S3 and the ticket type card on S8.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_type_spots_taken(p_event_id INT, p_type_name VARCHAR(50))
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_rsvps INT;
    DECLARE v_guests INT;

    SELECT COUNT(*) INTO v_rsvps
    FROM RSVP
    WHERE EventID = p_event_id AND TypeName = p_type_name AND RSVPStatus = 'Confirmed';

    SELECT COUNT(*) INTO v_guests
    FROM PLUS_ONE p
    INNER JOIN RSVP r ON r.RSVPID = p.RSVPID
    WHERE r.EventID = p_event_id AND r.TypeName = p_type_name AND r.RSVPStatus = 'Confirmed';

    RETURN v_rsvps + v_guests;
END$$

-- ---------------------------------------------------------------------
-- TRIGGER: checks a new RSVP before it is saved (business rules 7, 8, 9, 13 and 14).
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_rsvp_before_insert
BEFORE INSERT ON RSVP
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(10);
    DECLARE v_deadline DATETIME;
    DECLARE v_visibility VARCHAR(15);
    DECLARE v_approval BOOLEAN;
    DECLARE v_capacity INT;
    DECLARE v_type_capacity INT;
    DECLARE v_user_type VARCHAR(10);
    DECLARE v_invited INT;

    SELECT EventStatus, RSVPDeadline, Visibility, RequiresApproval, Capacity
    INTO v_status, v_deadline, v_visibility, v_approval, v_capacity
    FROM EVENT
    WHERE EventID = NEW.EventID;

    SELECT TypeCapacity INTO v_type_capacity
    FROM TICKET_TYPE
    WHERE EventID = NEW.EventID AND TypeName = NEW.TypeName;

    SELECT UserType INTO v_user_type FROM USER WHERE UserID = NEW.UserID;

    SELECT COUNT(*) INTO v_invited
    FROM INVITATION
    WHERE EventID = NEW.EventID AND InviteeID = NEW.UserID AND InvitationStatus <> 'Declined';

    -- Rule 7: only scheduled events, and only before the deadline
    IF v_status <> 'Scheduled' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can only RSVP to scheduled events.';
    END IF;
    IF NEW.SubmittedAt > v_deadline THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The RSVP deadline for this event has passed.';
    END IF;

    -- Rule 13: NYU-only and invite-only events
    IF v_visibility = 'NYU-only' AND v_user_type <> 'NYU' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only NYU users can RSVP to NYU-only events.';
    END IF;
    IF v_visibility = 'Invite-only' AND v_invited = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You need an invitation to RSVP to this event.';
    END IF;

    -- Rule 14: events that need approval start as Pending;
    -- other events start as Confirmed, or Waitlisted when full (rule 10)
    IF v_approval = TRUE AND NEW.RSVPStatus <> 'Pending' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSVPs for events that require approval must start as Pending.';
    END IF;
    IF v_approval = FALSE AND NEW.RSVPStatus NOT IN ('Confirmed', 'Waitlisted') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A new RSVP must start as Confirmed or Waitlisted.';
    END IF;

    -- Rules 8 and 9: a confirmed RSVP needs a free spot in the event AND in its ticket type,
    -- otherwise it goes on the waitlist
    IF NEW.RSVPStatus = 'Confirmed' AND fn_spots_taken(NEW.EventID) + 1 > v_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This event is full, so the RSVP must be waitlisted.';
    END IF;
    IF NEW.RSVPStatus = 'Confirmed'
       AND fn_type_spots_taken(NEW.EventID, NEW.TypeName) + 1 > v_type_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This ticket type is full, so the RSVP must be waitlisted.';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- TRIGGER: RSVPing to an invite-only event accepts the invitation
-- (Milestone 2 design: accepting an invitation means RSVPing).
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_rsvp_after_insert
AFTER INSERT ON RSVP
FOR EACH ROW
BEGIN
    UPDATE INVITATION
    SET InvitationStatus = 'Accepted'
    WHERE EventID = NEW.EventID
      AND InviteeID = NEW.UserID
      AND InvitationStatus = 'Sent';
END$$

-- ---------------------------------------------------------------------
-- TRIGGER: checks each plus-one before it is saved (business rules 8, 9 and 11).
-- Plus-ones are added right after their RSVP, so this is where the group size is checked.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_plus_one_before_insert
BEFORE INSERT ON PLUS_ONE
FOR EACH ROW
BEGIN
    DECLARE v_event INT;
    DECLARE v_type VARCHAR(50);
    DECLARE v_rsvp_status VARCHAR(12);
    DECLARE v_max INT;
    DECLARE v_capacity INT;
    DECLARE v_type_capacity INT;
    DECLARE v_current INT;

    SELECT r.EventID, r.TypeName, r.RSVPStatus, e.MaxPlusOnes, e.Capacity, t.TypeCapacity
    INTO v_event, v_type, v_rsvp_status, v_max, v_capacity, v_type_capacity
    FROM RSVP r
    INNER JOIN EVENT e ON e.EventID = r.EventID
    INNER JOIN TICKET_TYPE t ON t.EventID = r.EventID AND t.TypeName = r.TypeName
    WHERE r.RSVPID = NEW.RSVPID;

    SELECT COUNT(*) INTO v_current FROM PLUS_ONE WHERE RSVPID = NEW.RSVPID;

    -- Rule 11: no more guests than the event allows
    IF v_current + 1 > v_max THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This RSVP already has the maximum number of guests.';
    END IF;

    -- Rules 8 and 9: a guest of a confirmed RSVP takes a spot in the event and the ticket type
    IF v_rsvp_status = 'Confirmed' AND fn_spots_taken(v_event) + 1 > v_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'There is no space left in this event for another guest.';
    END IF;
    IF v_rsvp_status = 'Confirmed' AND fn_type_spots_taken(v_event, v_type) + 1 > v_type_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'There is no space left in this ticket type for another guest.';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- TRIGGER: when an event is cancelled, its active RSVPs are cancelled too (business rule 17).
-- Declined RSVPs keep their status, since they were never active.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_event_after_update
AFTER UPDATE ON EVENT
FOR EACH ROW
BEGIN
    IF NEW.EventStatus = 'Cancelled' AND OLD.EventStatus <> 'Cancelled' THEN
        UPDATE RSVP
        SET RSVPStatus = 'Cancelled'
        WHERE EventID = NEW.EventID
          AND RSVPStatus IN ('Pending', 'Confirmed', 'Waitlisted');
    END IF;
END$$

-- ---------------------------------------------------------------------
-- TRIGGER: only confirmed RSVPs can be checked in (business rule 16).
-- (The UNIQUE constraint on CHECK_IN.RSVPID already stops a second check-in.)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_check_in_before_insert
BEFORE INSERT ON CHECK_IN
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(12);

    SELECT RSVPStatus INTO v_status FROM RSVP WHERE RSVPID = NEW.RSVPID;

    IF v_status <> 'Confirmed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only people with a confirmed RSVP can be checked in.';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- STORED PROCEDURE: a user cancels their RSVP (S4). This is only allowed for
-- scheduled events that have not started yet (Milestone 2, S4). If the RSVP was
-- confirmed, the freed spots go to the waitlist in the order people submitted
-- (business rule 10). The waitlist never skips anyone: if the first person in line
-- (with their guests) does not fit in the event or in their ticket type,
-- nobody behind them moves up either.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_cancel_rsvp(IN p_rsvp_id INT, IN p_user_id INT)
BEGIN
    DECLARE v_event INT;
    DECLARE v_status VARCHAR(12);
    DECLARE v_event_status VARCHAR(10);
    DECLARE v_start DATETIME;
    DECLARE v_capacity INT;
    DECLARE v_next INT;
    DECLARE v_next_type VARCHAR(50);
    DECLARE v_type_capacity INT;
    DECLARE v_needed INT;
    DECLARE v_done INT DEFAULT 0;

    SELECT r.EventID, r.RSVPStatus, e.EventStatus, e.StartTime, e.Capacity
    INTO v_event, v_status, v_event_status, v_start, v_capacity
    FROM RSVP r
    INNER JOIN EVENT e ON e.EventID = r.EventID
    WHERE r.RSVPID = p_rsvp_id AND r.UserID = p_user_id;

    IF v_status IS NULL OR v_status NOT IN ('Pending', 'Confirmed', 'Waitlisted') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This RSVP cannot be cancelled.';
    END IF;
    IF v_event_status <> 'Scheduled' OR NOW() >= v_start THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSVPs can only be cancelled before the event starts.';
    END IF;

    UPDATE RSVP SET RSVPStatus = 'Cancelled' WHERE RSVPID = p_rsvp_id;

    IF v_status = 'Confirmed' THEN
        WHILE v_done = 0 DO
            -- the first person on the waitlist (earliest SubmittedAt)
            SET v_next = NULL;
            SELECT MIN(RSVPID) INTO v_next
            FROM RSVP
            WHERE EventID = v_event AND RSVPStatus = 'Waitlisted'
              AND SubmittedAt = (SELECT MIN(SubmittedAt) FROM RSVP
                                 WHERE EventID = v_event AND RSVPStatus = 'Waitlisted');

            IF v_next IS NULL THEN
                SET v_done = 1;
            ELSE
                -- spots this person needs: themselves plus their guests
                SELECT COUNT(*) + 1 INTO v_needed FROM PLUS_ONE WHERE RSVPID = v_next;

                SELECT r.TypeName, t.TypeCapacity INTO v_next_type, v_type_capacity
                FROM RSVP r
                INNER JOIN TICKET_TYPE t ON t.EventID = r.EventID AND t.TypeName = r.TypeName
                WHERE r.RSVPID = v_next;

                IF fn_spots_taken(v_event) + v_needed <= v_capacity
                   AND fn_type_spots_taken(v_event, v_next_type) + v_needed <= v_type_capacity THEN
                    UPDATE RSVP SET RSVPStatus = 'Confirmed' WHERE RSVPID = v_next;
                ELSE
                    SET v_done = 1;
                END IF;
            END IF;
        END WHILE;
    END IF;
END$$

DELIMITER ;
