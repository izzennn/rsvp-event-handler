-- MariaDB dump 10.19  Distrib 10.4.28-MariaDB, for osx10.10 (x86_64)
--
-- Host: localhost    Database: rsvp_db
-- ------------------------------------------------------
-- Server version	10.4.28-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `rsvp_db`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `rsvp_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;

USE `rsvp_db`;

--
-- Table structure for table `APPROVAL`
--

DROP TABLE IF EXISTS `APPROVAL`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `APPROVAL` (
  `ApprovalID` int(11) NOT NULL AUTO_INCREMENT,
  `RSVPID` int(11) NOT NULL,
  `ReviewedBy` int(11) NOT NULL,
  `Decision` varchar(10) NOT NULL,
  `DecidedAt` datetime NOT NULL,
  `Reason` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ApprovalID`),
  UNIQUE KEY `RSVPID` (`RSVPID`),
  KEY `ReviewedBy` (`ReviewedBy`),
  CONSTRAINT `approval_ibfk_1` FOREIGN KEY (`RSVPID`) REFERENCES `RSVP` (`RSVPID`),
  CONSTRAINT `approval_ibfk_2` FOREIGN KEY (`ReviewedBy`) REFERENCES `USER` (`UserID`),
  CONSTRAINT `chk_approval_decision` CHECK (`Decision` in ('Approved','Declined'))
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `APPROVAL`
--

LOCK TABLES `APPROVAL` WRITE;
/*!40000 ALTER TABLE `APPROVAL` DISABLE KEYS */;
INSERT INTO `APPROVAL` VALUES (1,72,20,'Approved','2026-10-17 04:42:00',NULL),(2,73,20,'Approved','2026-10-18 07:08:00',NULL),(3,74,20,'Approved','2026-10-24 07:29:00',NULL),(4,75,20,'Approved','2026-10-11 17:32:00',NULL),(5,76,20,'Approved','2026-10-09 14:52:00',NULL),(6,77,20,'Approved','2026-10-26 21:01:00',NULL),(7,78,20,'Approved','2026-10-19 13:09:00',NULL),(8,79,20,'Approved','2026-10-12 13:54:00',NULL),(9,80,20,'Approved','2026-10-12 21:59:00',NULL),(10,81,20,'Approved','2026-10-26 01:16:00',NULL),(11,82,20,'Approved','2026-10-14 23:05:00',NULL),(12,83,20,'Approved','2026-10-26 19:27:00',NULL),(13,84,20,'Approved','2026-10-16 15:54:00',NULL),(14,85,20,'Approved','2026-10-13 10:01:00',NULL),(15,86,20,'Declined','2026-10-19 04:47:00','We have already approved as many requests as we can for this demo night.'),(16,87,20,'Approved','2026-10-19 04:18:00',NULL),(17,148,23,'Approved','2026-10-30 16:13:00',NULL),(18,149,23,'Approved','2026-10-06 05:50:00',NULL),(19,150,23,'Approved','2026-10-16 22:10:00',NULL),(20,151,23,'Approved','2026-10-24 22:06:00',NULL),(21,152,23,'Approved','2026-10-30 18:29:00',NULL),(22,153,23,'Approved','2026-10-12 02:04:00',NULL),(23,154,23,'Approved','2026-10-15 10:44:00',NULL),(24,155,23,'Approved','2026-10-07 07:23:00',NULL),(25,156,23,'Approved','2026-10-16 18:21:00',NULL),(26,157,23,'Approved','2026-10-31 08:41:00',NULL),(27,158,23,'Approved','2026-10-08 07:16:00',NULL),(28,159,23,'Approved','2026-10-03 15:35:00',NULL),(29,160,23,'Approved','2026-10-09 06:35:00',NULL),(30,161,23,'Approved','2026-10-21 21:25:00',NULL),(31,166,23,'Declined','2026-10-08 20:48:00','This panel is for students who have finished intro to programming.'),(32,215,26,'Declined','2026-10-05 22:30:00','This year\'s formal is limited to residents of Third North.'),(33,216,26,'Approved','2026-10-08 11:54:00',NULL),(34,217,26,'Approved','2026-10-08 02:35:00',NULL),(35,218,26,'Approved','2026-11-03 11:21:00',NULL),(36,219,26,'Approved','2026-10-13 03:27:00',NULL),(37,220,26,'Approved','2026-10-13 17:48:00',NULL),(38,221,26,'Approved','2026-10-10 10:24:00',NULL),(39,222,26,'Approved','2026-10-22 08:56:00',NULL),(40,223,26,'Approved','2026-10-08 16:35:00',NULL),(41,224,26,'Approved','2026-10-20 03:30:00',NULL),(42,225,26,'Approved','2026-11-01 13:01:00',NULL),(43,226,26,'Approved','2026-10-22 17:54:00',NULL),(44,227,26,'Approved','2026-10-26 18:36:00',NULL),(45,231,1,'Approved','2026-10-02 18:44:00',NULL),(46,232,1,'Approved','2026-10-06 10:45:00',NULL),(47,233,1,'Approved','2026-09-29 20:53:00',NULL),(48,234,1,'Approved','2026-10-04 05:10:00',NULL),(49,235,1,'Approved','2026-09-29 20:28:00',NULL),(50,236,1,'Approved','2026-09-30 00:52:00',NULL),(51,237,1,'Approved','2026-09-30 15:44:00',NULL),(52,238,1,'Approved','2026-09-29 01:08:00',NULL),(53,239,1,'Approved','2026-10-03 11:59:00',NULL),(54,240,1,'Approved','2026-10-09 03:47:00',NULL),(55,241,1,'Approved','2026-09-30 09:17:00',NULL),(56,242,1,'Approved','2026-10-05 20:52:00',NULL),(57,243,1,'Approved','2026-10-08 19:09:00',NULL),(58,244,1,'Approved','2026-10-06 23:11:00',NULL),(59,245,1,'Approved','2026-10-04 16:45:00',NULL),(60,246,1,'Approved','2026-10-05 15:48:00',NULL),(61,247,1,'Approved','2026-10-01 15:52:00',NULL),(62,248,1,'Approved','2026-10-07 11:29:00',NULL),(63,249,1,'Approved','2026-10-07 12:26:00',NULL),(64,250,1,'Approved','2026-10-07 04:28:00',NULL),(65,251,1,'Approved','2026-10-09 10:00:00',NULL),(66,252,1,'Approved','2026-10-11 09:30:00',NULL),(67,256,1,'Declined','2026-10-06 18:49:00','This workshop is for students in the Creative Writing minor this term.'),(68,257,1,'Approved','2026-10-02 02:37:00',NULL),(69,304,23,'Approved','2026-11-03 10:25:00',NULL),(70,305,23,'Approved','2026-11-02 02:26:00',NULL);
/*!40000 ALTER TABLE `APPROVAL` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CHECK_IN`
--

DROP TABLE IF EXISTS `CHECK_IN`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `CHECK_IN` (
  `CheckInID` int(11) NOT NULL AUTO_INCREMENT,
  `RSVPID` int(11) NOT NULL,
  `CheckedInBy` int(11) NOT NULL,
  `CheckedInAt` datetime NOT NULL,
  PRIMARY KEY (`CheckInID`),
  UNIQUE KEY `RSVPID` (`RSVPID`),
  KEY `CheckedInBy` (`CheckedInBy`),
  CONSTRAINT `check_in_ibfk_1` FOREIGN KEY (`RSVPID`) REFERENCES `RSVP` (`RSVPID`),
  CONSTRAINT `check_in_ibfk_2` FOREIGN KEY (`CheckedInBy`) REFERENCES `USER` (`UserID`)
) ENGINE=InnoDB AUTO_INCREMENT=107 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CHECK_IN`
--

LOCK TABLES `CHECK_IN` WRITE;
/*!40000 ALTER TABLE `CHECK_IN` DISABLE KEYS */;
INSERT INTO `CHECK_IN` VALUES (1,1,20,'2026-09-04 18:12:00'),(2,2,20,'2026-09-04 18:34:00'),(3,3,20,'2026-09-04 17:48:00'),(4,4,20,'2026-09-04 18:13:00'),(5,5,20,'2026-09-04 18:37:00'),(6,6,20,'2026-09-04 17:48:00'),(7,7,20,'2026-09-04 18:08:00'),(8,8,20,'2026-09-04 17:54:00'),(9,9,20,'2026-09-04 18:20:00'),(10,10,20,'2026-09-04 17:48:00'),(11,11,20,'2026-09-04 18:15:00'),(12,16,20,'2026-09-25 18:37:00'),(13,17,20,'2026-09-25 18:36:00'),(14,18,20,'2026-09-25 17:41:00'),(15,19,20,'2026-09-25 18:24:00'),(16,20,20,'2026-09-25 17:51:00'),(17,21,20,'2026-09-25 17:52:00'),(18,22,20,'2026-09-25 17:57:00'),(19,23,20,'2026-09-25 18:15:00'),(20,24,20,'2026-09-25 18:03:00'),(21,31,1,'2026-10-02 18:43:00'),(22,32,1,'2026-10-02 19:26:00'),(23,33,1,'2026-10-02 18:47:00'),(24,34,1,'2026-10-02 19:19:00'),(25,35,1,'2026-10-02 18:49:00'),(26,36,1,'2026-10-02 19:06:00'),(27,37,1,'2026-10-02 18:55:00'),(28,38,1,'2026-10-02 19:17:00'),(29,39,1,'2026-10-02 18:54:00'),(30,40,1,'2026-10-02 19:08:00'),(31,41,1,'2026-10-02 19:39:00'),(32,42,1,'2026-10-02 19:20:00'),(33,43,1,'2026-10-02 19:05:00'),(34,44,1,'2026-10-02 19:34:00'),(35,45,1,'2026-10-02 19:00:00'),(36,46,1,'2026-10-02 19:10:00'),(37,47,1,'2026-10-02 19:04:00'),(38,48,1,'2026-10-02 19:16:00'),(39,49,1,'2026-10-02 18:51:00'),(40,50,1,'2026-10-02 19:17:00'),(41,51,1,'2026-10-02 19:05:00'),(42,52,1,'2026-10-02 19:07:00'),(43,54,1,'2026-10-02 19:38:00'),(44,55,1,'2026-10-02 18:54:00'),(45,56,1,'2026-10-02 19:16:00'),(46,57,1,'2026-10-02 19:06:00'),(47,72,20,'2026-10-30 18:24:00'),(48,73,20,'2026-10-30 18:05:00'),(49,74,20,'2026-10-30 18:24:00'),(50,75,20,'2026-10-30 18:32:00'),(51,76,20,'2026-10-30 18:13:00'),(52,78,20,'2026-10-30 18:30:00'),(53,79,20,'2026-10-30 18:39:00'),(54,80,20,'2026-10-30 18:27:00'),(55,81,20,'2026-10-30 17:51:00'),(56,83,20,'2026-10-30 18:35:00'),(57,84,20,'2026-10-30 17:54:00'),(58,85,20,'2026-10-30 18:02:00'),(59,88,13,'2026-11-03 17:59:00'),(60,89,13,'2026-11-03 17:24:00'),(61,90,13,'2026-11-03 17:37:00'),(62,91,13,'2026-11-03 17:51:00'),(63,92,13,'2026-11-03 17:47:00'),(64,93,13,'2026-11-03 18:01:00'),(65,94,13,'2026-11-03 17:24:00'),(66,95,13,'2026-11-03 17:13:00'),(67,98,1,'2026-11-05 20:19:00'),(68,99,1,'2026-11-05 20:10:00'),(69,100,1,'2026-11-05 20:05:00'),(70,101,1,'2026-11-05 20:02:00'),(71,102,1,'2026-11-05 20:12:00'),(72,104,1,'2026-11-05 19:44:00'),(73,105,1,'2026-11-05 19:33:00'),(74,106,1,'2026-11-05 19:42:00'),(75,107,1,'2026-11-05 19:12:00'),(76,108,1,'2026-11-05 19:37:00'),(77,109,1,'2026-11-05 20:14:00'),(78,110,1,'2026-11-05 19:15:00'),(79,112,1,'2026-11-05 20:13:00'),(80,113,1,'2026-11-05 19:24:00'),(81,114,1,'2026-11-05 19:46:00'),(82,115,1,'2026-11-05 20:13:00'),(83,116,1,'2026-11-05 19:12:00'),(84,117,1,'2026-11-05 19:28:00'),(85,119,1,'2026-11-05 20:19:00'),(86,121,1,'2026-11-05 19:46:00'),(87,123,21,'2026-11-07 19:40:00'),(88,124,21,'2026-11-07 18:11:00'),(89,125,21,'2026-11-07 18:28:00'),(90,126,21,'2026-11-07 18:40:00'),(91,127,21,'2026-11-07 18:41:00'),(92,128,21,'2026-11-07 18:44:00'),(93,129,21,'2026-11-07 18:36:00'),(94,130,21,'2026-11-07 19:54:00'),(95,131,21,'2026-11-07 19:34:00'),(96,132,21,'2026-11-07 19:28:00'),(97,133,21,'2026-11-07 19:20:00'),(98,134,21,'2026-11-07 18:49:00'),(99,135,21,'2026-11-07 18:10:00'),(100,136,21,'2026-11-07 19:38:00'),(101,137,21,'2026-11-07 19:26:00'),(102,138,21,'2026-11-07 19:23:00'),(103,140,21,'2026-11-07 18:12:00'),(104,141,21,'2026-11-07 19:15:00'),(105,142,21,'2026-11-07 19:14:00'),(106,143,21,'2026-11-07 19:31:00');
/*!40000 ALTER TABLE `CHECK_IN` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_check_in_before_insert
BEFORE INSERT ON CHECK_IN
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(12);

    SELECT RSVPStatus INTO v_status FROM RSVP WHERE RSVPID = NEW.RSVPID;

    IF v_status <> 'Confirmed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only people with a confirmed RSVP can be checked in.';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `EVENT`
--

DROP TABLE IF EXISTS `EVENT`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `EVENT` (
  `EventID` int(11) NOT NULL AUTO_INCREMENT,
  `OrgID` int(11) NOT NULL,
  `VenueID` int(11) NOT NULL,
  `Title` varchar(150) NOT NULL,
  `Description` varchar(1000) DEFAULT NULL,
  `StartTime` datetime NOT NULL,
  `EndTime` datetime NOT NULL,
  `Capacity` int(11) NOT NULL,
  `RequiresApproval` tinyint(1) NOT NULL DEFAULT 0,
  `Visibility` varchar(15) NOT NULL DEFAULT 'Public',
  `MaxPlusOnes` int(11) NOT NULL DEFAULT 0,
  `RSVPDeadline` datetime NOT NULL,
  `EventStatus` varchar(10) NOT NULL DEFAULT 'Scheduled',
  PRIMARY KEY (`EventID`),
  KEY `OrgID` (`OrgID`),
  KEY `VenueID` (`VenueID`),
  CONSTRAINT `event_ibfk_1` FOREIGN KEY (`OrgID`) REFERENCES `ORGANIZATION` (`OrgID`),
  CONSTRAINT `event_ibfk_2` FOREIGN KEY (`VenueID`) REFERENCES `VENUE` (`VenueID`),
  CONSTRAINT `chk_event_times` CHECK (`EndTime` > `StartTime`),
  CONSTRAINT `chk_event_deadline` CHECK (`RSVPDeadline` < `StartTime`),
  CONSTRAINT `chk_event_capacity` CHECK (`Capacity` > 0),
  CONSTRAINT `chk_event_plusones` CHECK (`MaxPlusOnes` >= 0),
  CONSTRAINT `chk_event_visibility` CHECK (`Visibility` in ('Public','NYU-only','Invite-only')),
  CONSTRAINT `chk_event_status` CHECK (`EventStatus` in ('Scheduled','Cancelled','Completed'))
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `EVENT`
--

LOCK TABLES `EVENT` WRITE;
/*!40000 ALTER TABLE `EVENT` DISABLE KEYS */;
INSERT INTO `EVENT` VALUES (1,2,1,'Welcome Week Mixer','Meet the robotics teams, see last year\'s robots and grab some snacks.','2026-09-04 18:00:00','2026-09-04 20:00:00',50,0,'Public',0,'2026-09-03 23:59:00','Completed'),(2,2,1,'Intro to ROS Workshop','A hands-on introduction to the Robot Operating System. Bring a laptop.','2026-09-25 18:00:00','2026-09-25 20:00:00',30,0,'NYU-only',0,'2026-09-24 23:59:00','Completed'),(3,1,4,'Fall Reading Night','Members read new poems and short prose. Guests welcome.','2026-10-02 19:00:00','2026-10-02 21:00:00',40,0,'Public',1,'2026-10-01 23:59:00','Completed'),(4,1,4,'Slam Poetry Showcase','Our first slam of the semester, judged by the audience.','2026-10-22 20:00:00','2026-10-22 22:00:00',60,0,'Public',0,'2026-10-21 23:59:00','Cancelled'),(5,7,5,'Salsa Social','A relaxed social dance night with a beginner lesson at the start.','2026-10-24 19:00:00','2026-10-24 22:00:00',100,0,'Public',1,'2026-10-23 23:59:00','Cancelled'),(6,2,1,'Robotics Demo Night','Come see the robots our teams built this semester. Live demos, a short talk from our captains, and free pizza. Open to everyone who wants to learn about robotics at NYU.','2026-10-30 18:00:00','2026-10-30 21:00:00',60,1,'Public',2,'2026-10-29 23:59:00','Completed'),(7,4,3,'Founders Fireside Chat','An informal conversation with two NYU alumni founders about their first year.','2026-11-03 17:30:00','2026-11-03 19:00:00',40,0,'Invite-only',0,'2026-11-02 23:59:00','Completed'),(8,1,4,'Open Mic Night','Bring a poem, a song or just yourself. Readers get 5 minutes each.','2026-11-05 20:00:00','2026-11-05 22:00:00',80,0,'Public',1,'2026-11-04 23:59:00','Completed'),(9,5,5,'Diwali Gala','Dinner, performances and dancing to celebrate Diwali.','2026-11-07 19:00:00','2026-11-07 23:00:00',30,0,'NYU-only',1,'2026-11-06 23:59:00','Completed'),(10,3,6,'Career Panel: Data Science','Four data scientists talk about their path into the field, followed by Q&A.','2026-11-11 18:00:00','2026-11-11 19:30:00',50,1,'Public',0,'2026-11-10 23:59:00','Scheduled'),(11,6,2,'Hackathon Kickoff','Meet teammates, hear the theme and get ready for 24 hours of building.','2026-11-13 18:00:00','2026-11-13 20:00:00',16,0,'NYU-only',0,'2026-11-12 23:59:00','Scheduled'),(12,10,6,'Board Game Night','Chess, Catan and more. Snacks provided.','2026-11-14 19:00:00','2026-11-14 22:00:00',30,0,'Invite-only',1,'2026-11-13 23:59:00','Scheduled'),(13,8,6,'Film Night: Spirited Away','Screening of Spirited Away with a short discussion afterwards.','2026-11-18 19:00:00','2026-11-18 21:30:00',50,0,'Public',1,'2026-11-17 23:59:00','Scheduled'),(14,4,3,'Alumni Networking Night','Small-group networking with alumni working in startups and venture capital.','2026-11-19 18:00:00','2026-11-19 20:00:00',40,0,'Invite-only',0,'2026-11-18 23:59:00','Scheduled'),(15,9,5,'Fall Formal','The annual residence hall formal with a DJ and dinner.','2026-11-20 20:00:00','2026-11-20 23:30:00',150,1,'NYU-only',1,'2026-11-19 23:59:00','Scheduled'),(16,1,6,'Haiku Writing Workshop','A two-hour workshop on writing and sharing haiku.','2026-11-21 14:00:00','2026-11-21 16:00:00',20,1,'NYU-only',0,'2026-11-20 23:59:00','Scheduled'),(17,1,4,'Poets\' Circle Dinner','A small dinner for members to share work in progress.','2026-12-05 18:30:00','2026-12-05 20:30:00',12,0,'Invite-only',1,'2026-12-04 23:59:00','Scheduled'),(18,1,4,'Winter Poetry Slam','Our end-of-semester slam. Sign up to perform a poem (3 minutes max) or come to listen and vote.','2026-12-10 19:00:00','2026-12-10 21:30:00',60,0,'Public',1,'2026-12-09 23:59:00','Scheduled'),(19,11,12,'Photo Walk: Brooklyn Bridge at Sunrise','Meet at Kimmel and walk to the bridge for sunrise shots. All cameras welcome.','2027-02-06 06:30:00','2027-02-06 09:30:00',25,0,'Public',1,'2027-02-05 23:59:00','Scheduled'),(20,3,8,'Women in Tech Brunch','Brunch and table conversations with women engineers from NYC companies.','2027-02-20 11:00:00','2027-02-20 13:00:00',40,1,'NYU-only',0,'2027-02-19 23:59:00','Scheduled'),(21,4,10,'Startup Pitch Night','Student teams pitch to a panel of founders and investors.','2027-03-04 18:30:00','2027-03-04 21:00:00',100,0,'Public',2,'2027-03-03 23:59:00','Scheduled'),(22,2,2,'Spring Robotics Expo','Every team shows its spring build. Families and friends welcome.','2027-03-12 17:00:00','2027-03-12 20:00:00',150,0,'Public',2,'2027-03-11 23:59:00','Scheduled'),(23,7,11,'Bachata Basics','A beginner bachata class. No partner needed.','2027-02-11 19:00:00','2027-02-11 21:00:00',40,0,'Public',1,'2027-02-10 23:59:00','Scheduled'),(24,8,9,'Anime Drawing Night','Draw your favorite characters with tips from club artists.','2027-02-17 18:00:00','2027-02-17 20:00:00',30,0,'Public',0,'2027-02-16 23:59:00','Scheduled'),(25,12,7,'Short Film Showcase','Screening of short films made by NYU students, with Q&A.','2027-02-25 19:00:00','2027-02-25 21:00:00',40,0,'Public',1,'2027-02-24 23:59:00','Scheduled');
/*!40000 ALTER TABLE `EVENT` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_event_after_update
AFTER UPDATE ON EVENT
FOR EACH ROW
BEGIN
    IF NEW.EventStatus = 'Cancelled' AND OLD.EventStatus <> 'Cancelled' THEN
        UPDATE RSVP
        SET RSVPStatus = 'Cancelled'
        WHERE EventID = NEW.EventID
          AND RSVPStatus IN ('Pending', 'Confirmed', 'Waitlisted');
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `INVITATION`
--

DROP TABLE IF EXISTS `INVITATION`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `INVITATION` (
  `InvitationID` int(11) NOT NULL AUTO_INCREMENT,
  `EventID` int(11) NOT NULL,
  `InviteeID` int(11) NOT NULL,
  `InvitedBy` int(11) NOT NULL,
  `SentAt` datetime NOT NULL,
  `InvitationStatus` varchar(10) NOT NULL DEFAULT 'Sent',
  PRIMARY KEY (`InvitationID`),
  UNIQUE KEY `EventID` (`EventID`,`InviteeID`),
  KEY `InviteeID` (`InviteeID`),
  KEY `InvitedBy` (`InvitedBy`),
  CONSTRAINT `invitation_ibfk_1` FOREIGN KEY (`EventID`) REFERENCES `EVENT` (`EventID`),
  CONSTRAINT `invitation_ibfk_2` FOREIGN KEY (`InviteeID`) REFERENCES `USER` (`UserID`),
  CONSTRAINT `invitation_ibfk_3` FOREIGN KEY (`InvitedBy`) REFERENCES `USER` (`UserID`),
  CONSTRAINT `chk_invitation_status` CHECK (`InvitationStatus` in ('Sent','Accepted','Declined'))
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `INVITATION`
--

LOCK TABLES `INVITATION` WRITE;
/*!40000 ALTER TABLE `INVITATION` DISABLE KEYS */;
INSERT INTO `INVITATION` VALUES (1,7,1,13,'2026-10-01 10:00:00','Accepted'),(2,7,33,13,'2026-10-01 16:27:00','Accepted'),(3,7,26,13,'2026-10-02 13:02:00','Sent'),(4,7,19,13,'2026-10-03 05:07:00','Accepted'),(5,7,37,13,'2026-10-03 22:27:00','Declined'),(6,7,20,13,'2026-10-04 01:57:00','Accepted'),(7,7,30,13,'2026-10-04 23:19:00','Accepted'),(8,7,21,13,'2026-10-05 09:09:00','Accepted'),(9,7,7,13,'2026-10-05 19:26:00','Accepted'),(10,7,40,13,'2026-10-07 03:23:00','Accepted'),(11,7,50,13,'2026-10-08 09:43:00','Accepted'),(12,7,24,13,'2026-10-08 12:12:00','Accepted'),(13,12,1,15,'2026-10-05 12:00:00','Declined'),(14,12,9,15,'2026-10-09 10:37:00','Sent'),(15,12,5,15,'2026-10-10 00:53:00','Accepted'),(16,12,22,15,'2026-10-10 20:07:00','Accepted'),(17,12,27,15,'2026-10-14 06:26:00','Sent'),(18,12,19,15,'2026-10-14 08:26:00','Accepted'),(19,12,49,15,'2026-10-14 20:59:00','Accepted'),(20,12,31,15,'2026-10-18 04:44:00','Accepted'),(21,12,17,15,'2026-10-19 01:40:00','Accepted'),(22,12,21,15,'2026-10-19 19:39:00','Accepted'),(23,14,1,13,'2026-10-12 09:30:00','Sent'),(24,14,34,13,'2026-10-13 05:20:00','Accepted'),(25,14,45,13,'2026-10-13 05:22:00','Accepted'),(26,14,46,13,'2026-10-14 12:27:00','Accepted'),(27,14,40,13,'2026-10-17 17:28:00','Sent'),(28,14,7,13,'2026-10-17 21:40:00','Accepted'),(29,14,9,13,'2026-10-19 21:55:00','Accepted'),(30,14,33,13,'2026-10-22 08:58:00','Accepted'),(31,14,37,13,'2026-10-23 20:59:00','Accepted'),(32,14,5,13,'2026-10-23 22:11:00','Sent'),(33,14,3,13,'2026-10-24 13:01:00','Accepted'),(34,17,2,1,'2026-10-03 10:00:00','Accepted'),(35,17,3,1,'2026-10-03 10:00:00','Accepted'),(36,17,4,1,'2026-10-03 10:05:00','Accepted'),(37,17,6,1,'2026-10-05 14:30:00','Accepted'),(38,17,5,1,'2026-10-05 14:35:00','Accepted'),(39,17,10,1,'2026-10-05 14:40:00','Declined'),(40,17,7,1,'2026-10-14 11:00:00','Sent'),(41,17,8,1,'2026-10-14 11:02:00','Sent');
/*!40000 ALTER TABLE `INVITATION` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ORGANIZATION`
--

DROP TABLE IF EXISTS `ORGANIZATION`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ORGANIZATION` (
  `OrgID` int(11) NOT NULL AUTO_INCREMENT,
  `OrgName` varchar(100) NOT NULL,
  `ContactEmail` varchar(100) NOT NULL,
  `Description` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`OrgID`),
  UNIQUE KEY `OrgName` (`OrgName`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ORGANIZATION`
--

LOCK TABLES `ORGANIZATION` WRITE;
/*!40000 ALTER TABLE `ORGANIZATION` DISABLE KEYS */;
INSERT INTO `ORGANIZATION` VALUES (1,'Poetry Society','poetry.society@nyu.edu','Open mics, workshops and readings for anyone who loves writing.'),(2,'NYU Robotics Club','robotics.club@nyu.edu','Build, program and demo robots with student teams.'),(3,'Women in Computing','wic@nyu.edu','Community, mentoring and career events for women in tech.'),(4,'Entrepreneurs Club','eclub@nyu.edu','Founder talks, pitch nights and startup networking.'),(5,'South Asian Students Association','sasa@nyu.edu','Celebrating South Asian culture through food, music and festivals.'),(6,'Tech@NYU','tech@nyu.edu','Hackathons, workshops and a community of student builders.'),(7,'Latin Dance Club','latindance@nyu.edu','Salsa, bachata and merengue nights for all levels.'),(8,'Anime Club','anime.club@nyu.edu','Weekly screenings, drawing nights and cosplay meetups.'),(9,'Residence Hall Council','rhc@nyu.edu','Events and community building for NYU residence halls.'),(10,'Chess Club','chess.club@nyu.edu','Casual games, puzzles and tournaments for every level.'),(11,'NYU Photography Club','photoclub@nyu.edu','Photo walks around the city and editing workshops.'),(12,'Film Society','film.society@nyu.edu',NULL);
/*!40000 ALTER TABLE `ORGANIZATION` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ORG_MEMBERSHIP`
--

DROP TABLE IF EXISTS `ORG_MEMBERSHIP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ORG_MEMBERSHIP` (
  `UserID` int(11) NOT NULL,
  `OrgID` int(11) NOT NULL,
  `Role` varchar(10) NOT NULL,
  `JoinedDate` date NOT NULL,
  PRIMARY KEY (`UserID`,`OrgID`),
  KEY `OrgID` (`OrgID`),
  CONSTRAINT `org_membership_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `USER` (`UserID`),
  CONSTRAINT `org_membership_ibfk_2` FOREIGN KEY (`OrgID`) REFERENCES `ORGANIZATION` (`OrgID`),
  CONSTRAINT `chk_membership_role` CHECK (`Role` in ('Officer','Member'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ORG_MEMBERSHIP`
--

LOCK TABLES `ORG_MEMBERSHIP` WRITE;
/*!40000 ALTER TABLE `ORG_MEMBERSHIP` DISABLE KEYS */;
INSERT INTO `ORG_MEMBERSHIP` VALUES (1,1,'Officer','2025-09-10'),(1,2,'Member','2026-09-02'),(1,3,'Member','2026-02-14'),(2,1,'Member','2025-09-18'),(2,2,'Member','2025-09-12'),(3,1,'Member','2026-01-22'),(3,3,'Member','2025-10-02'),(4,1,'Member','2026-09-08'),(5,1,'Member','2026-09-30'),(11,10,'Member','2025-09-11'),(12,8,'Member','2025-09-17'),(13,4,'Officer','2025-01-28'),(14,11,'Officer','2026-03-01'),(15,10,'Officer','2025-02-20'),(17,11,'Member','2026-09-12'),(20,2,'Officer','2025-02-03'),(21,5,'Officer','2025-03-12'),(22,6,'Officer','2024-10-02'),(23,3,'Officer','2024-09-15'),(23,7,'Member','2026-02-04'),(24,7,'Officer','2025-01-15'),(25,8,'Officer','2025-04-08'),(26,9,'Officer','2025-08-28'),(27,12,'Officer','2025-09-01'),(28,2,'Member','2026-01-20'),(28,5,'Member','2025-09-14'),(29,5,'Member','2026-09-06'),(30,4,'Member','2025-09-20'),(31,9,'Member','2026-09-01'),(32,7,'Member','2025-09-25'),(33,9,'Member','2025-09-02'),(34,4,'Member','2026-02-11'),(34,10,'Member','2026-03-05'),(35,3,'Member','2026-02-01'),(35,8,'Member','2026-01-30'),(36,5,'Member','2025-10-01'),(37,3,'Member','2026-09-10'),(38,12,'Member','2025-09-19'),(39,12,'Member','2026-01-27'),(40,2,'Officer','2025-09-05'),(40,6,'Member','2025-11-18'),(41,11,'Member','2026-03-15'),(42,6,'Officer','2025-09-09'),(44,6,'Member','2026-09-03');
/*!40000 ALTER TABLE `ORG_MEMBERSHIP` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `PLUS_ONE`
--

DROP TABLE IF EXISTS `PLUS_ONE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `PLUS_ONE` (
  `RSVPID` int(11) NOT NULL,
  `GuestNo` int(11) NOT NULL,
  `GuestName` varchar(100) NOT NULL,
  `GuestEmail` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`RSVPID`,`GuestNo`),
  CONSTRAINT `plus_one_ibfk_1` FOREIGN KEY (`RSVPID`) REFERENCES `RSVP` (`RSVPID`),
  CONSTRAINT `chk_guest_no` CHECK (`GuestNo` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `PLUS_ONE`
--

LOCK TABLES `PLUS_ONE` WRITE;
/*!40000 ALTER TABLE `PLUS_ONE` DISABLE KEYS */;
INSERT INTO `PLUS_ONE` VALUES (28,1,'Chris Hall',NULL),(33,1,'Dana Price',NULL),(37,1,'Ethan Wu',NULL),(42,1,'Faye Lin',NULL),(48,1,'Gabe Ross',NULL),(66,1,'Hope Kerr',NULL),(72,1,'Alex Kim','alex@gmail.com'),(75,1,'Ian Moss',NULL),(79,1,'Jade Fox',NULL),(82,1,'Kyle Dunn',NULL),(99,1,'Ben Lee',NULL),(100,1,'Dev Shah',NULL),(107,1,'Lara Vos',NULL),(112,1,'Milo Park',NULL),(123,1,'Nia Bell',NULL),(124,1,'Oscar Gray',NULL),(125,1,'Pia Lund',NULL),(126,1,'Quinn Ray',NULL),(127,1,'Rosa Diaz',NULL),(128,1,'Seth Cole',NULL),(129,1,'Tara Wells',NULL),(130,1,'Uma Rao',NULL),(147,1,'Riya Patel',NULL),(187,1,'Vic Hale',NULL),(190,1,'Julia Chen',NULL),(194,1,'Max Fischer',NULL),(198,1,'Ana Lopez',NULL),(201,1,'Tom Becker',NULL),(215,1,'Leo Garcia',NULL),(217,1,'Lily Tran',NULL),(219,1,'Owen Shaw',NULL),(222,1,'Ivy Morgan',NULL),(226,1,'Raj Kapoor',NULL),(258,1,'Nora Hayes',NULL),(261,1,'Sam Ortiz',NULL),(264,1,'Eva Novak',NULL),(268,1,'Finn Doyle',NULL),(273,1,'Zara Malik',NULL),(279,1,'Hugo Lam',NULL),(285,1,'Kira Sato',NULL),(290,1,'Ella Byrne',NULL),(300,1,'Noor Aziz',NULL);
/*!40000 ALTER TABLE `PLUS_ONE` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_plus_one_before_insert
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `RSVP`
--

DROP TABLE IF EXISTS `RSVP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `RSVP` (
  `RSVPID` int(11) NOT NULL AUTO_INCREMENT,
  `EventID` int(11) NOT NULL,
  `TypeName` varchar(50) NOT NULL,
  `UserID` int(11) NOT NULL,
  `SubmittedAt` datetime NOT NULL,
  `RSVPStatus` varchar(12) NOT NULL,
  PRIMARY KEY (`RSVPID`),
  UNIQUE KEY `EventID` (`EventID`,`UserID`),
  KEY `EventID_2` (`EventID`,`TypeName`),
  KEY `UserID` (`UserID`),
  CONSTRAINT `rsvp_ibfk_1` FOREIGN KEY (`EventID`, `TypeName`) REFERENCES `TICKET_TYPE` (`EventID`, `TypeName`),
  CONSTRAINT `rsvp_ibfk_2` FOREIGN KEY (`UserID`) REFERENCES `USER` (`UserID`),
  CONSTRAINT `chk_rsvp_status` CHECK (`RSVPStatus` in ('Pending','Confirmed','Waitlisted','Declined','Cancelled'))
) ENGINE=InnoDB AUTO_INCREMENT=310 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `RSVP`
--

LOCK TABLES `RSVP` WRITE;
/*!40000 ALTER TABLE `RSVP` DISABLE KEYS */;
INSERT INTO `RSVP` VALUES (1,1,'General',1,'2026-08-30 14:05:00','Confirmed'),(2,1,'General',47,'2026-08-25 09:49:00','Confirmed'),(3,1,'General',16,'2026-09-02 23:11:00','Confirmed'),(4,1,'General',21,'2026-08-28 18:11:00','Confirmed'),(5,1,'General',23,'2026-09-02 13:51:00','Confirmed'),(6,1,'General',10,'2026-08-28 14:45:00','Confirmed'),(7,1,'General',25,'2026-09-03 01:03:00','Confirmed'),(8,1,'General',48,'2026-09-01 23:05:00','Confirmed'),(9,1,'General',27,'2026-09-02 23:25:00','Confirmed'),(10,1,'General',38,'2026-08-31 12:52:00','Confirmed'),(11,1,'General',11,'2026-08-26 17:39:00','Confirmed'),(12,1,'General',14,'2026-09-02 13:58:00','Confirmed'),(13,1,'General',4,'2026-08-27 02:10:00','Confirmed'),(14,1,'General',22,'2026-08-29 18:25:00','Confirmed'),(15,2,'General',1,'2026-09-14 10:20:00','Confirmed'),(16,2,'General',33,'2026-09-23 12:47:00','Confirmed'),(17,2,'General',41,'2026-09-22 07:22:00','Confirmed'),(18,2,'General',10,'2026-09-13 17:39:00','Confirmed'),(19,2,'General',36,'2026-09-21 10:13:00','Confirmed'),(20,2,'General',28,'2026-09-17 12:58:00','Confirmed'),(21,2,'General',8,'2026-09-18 01:15:00','Confirmed'),(22,2,'General',27,'2026-09-23 22:49:00','Confirmed'),(23,2,'General',2,'2026-09-14 23:15:00','Confirmed'),(24,2,'General',43,'2026-09-17 07:20:00','Confirmed'),(25,2,'General',6,'2026-09-11 19:49:00','Confirmed'),(26,2,'General',32,'2026-09-19 22:57:00','Confirmed'),(27,2,'General',34,'2026-09-21 16:51:00','Cancelled'),(28,3,'General',16,'2026-09-16 16:37:00','Confirmed'),(29,3,'General',17,'2026-09-24 18:40:00','Confirmed'),(30,3,'General',18,'2026-09-25 22:11:00','Confirmed'),(31,3,'General',36,'2026-09-17 02:15:00','Confirmed'),(32,3,'General',41,'2026-09-27 19:08:00','Confirmed'),(33,3,'General',30,'2026-09-23 00:43:00','Confirmed'),(34,3,'General',6,'2026-09-23 07:08:00','Confirmed'),(35,3,'General',5,'2026-09-27 21:33:00','Confirmed'),(36,3,'General',15,'2026-09-29 02:16:00','Confirmed'),(37,3,'General',7,'2026-09-22 03:11:00','Confirmed'),(38,3,'General',24,'2026-09-25 08:02:00','Confirmed'),(39,3,'General',14,'2026-09-23 07:16:00','Confirmed'),(40,3,'General',34,'2026-09-29 14:19:00','Confirmed'),(41,3,'General',35,'2026-09-23 03:33:00','Confirmed'),(42,3,'General',38,'2026-09-17 03:38:00','Confirmed'),(43,3,'General',4,'2026-09-17 02:35:00','Confirmed'),(44,3,'General',25,'2026-09-22 15:18:00','Confirmed'),(45,3,'General',8,'2026-09-16 23:39:00','Confirmed'),(46,3,'General',23,'2026-09-25 20:17:00','Confirmed'),(47,3,'General',26,'2026-09-24 04:38:00','Confirmed'),(48,3,'General',42,'2026-09-30 10:38:00','Confirmed'),(49,3,'General',28,'2026-09-25 05:19:00','Confirmed'),(50,3,'General',29,'2026-10-01 09:28:00','Confirmed'),(51,3,'General',46,'2026-09-28 21:24:00','Confirmed'),(52,3,'General',49,'2026-09-26 14:49:00','Confirmed'),(53,3,'Reader',19,'2026-09-24 21:49:00','Confirmed'),(54,3,'Reader',44,'2026-09-17 19:00:00','Confirmed'),(55,3,'Reader',10,'2026-09-19 16:20:00','Confirmed'),(56,3,'Reader',12,'2026-09-21 02:09:00','Confirmed'),(57,3,'Reader',27,'2026-09-26 17:36:00','Confirmed'),(58,4,'General',35,'2026-10-15 15:08:00','Cancelled'),(59,4,'General',4,'2026-10-13 23:13:00','Cancelled'),(60,4,'General',38,'2026-10-14 19:37:00','Cancelled'),(61,4,'General',23,'2026-10-12 06:56:00','Cancelled'),(62,4,'General',12,'2026-10-12 13:41:00','Cancelled'),(63,4,'General',24,'2026-10-08 16:45:00','Cancelled'),(64,5,'General',1,'2026-10-01 19:30:00','Cancelled'),(65,5,'General',18,'2026-10-10 02:15:00','Cancelled'),(66,5,'General',26,'2026-10-04 03:13:00','Cancelled'),(67,5,'General',5,'2026-09-30 07:32:00','Cancelled'),(68,5,'General',46,'2026-09-30 20:20:00','Cancelled'),(69,5,'General',4,'2026-09-29 21:56:00','Cancelled'),(70,5,'General',35,'2026-09-28 19:20:00','Cancelled'),(71,5,'General',23,'2026-10-06 03:02:00','Cancelled'),(72,6,'General',1,'2026-10-15 23:42:00','Confirmed'),(73,6,'VIP',23,'2026-10-16 22:08:00','Confirmed'),(74,6,'VIP',48,'2026-10-23 07:29:00','Confirmed'),(75,6,'VIP',33,'2026-10-10 04:32:00','Confirmed'),(76,6,'VIP',41,'2026-10-09 08:52:00','Confirmed'),(77,6,'General',34,'2026-10-25 08:01:00','Confirmed'),(78,6,'General',7,'2026-10-18 19:09:00','Confirmed'),(79,6,'General',17,'2026-10-11 12:54:00','Confirmed'),(80,6,'General',45,'2026-10-12 10:59:00','Confirmed'),(81,6,'General',43,'2026-10-24 11:16:00','Confirmed'),(82,6,'General',16,'2026-10-13 23:05:00','Confirmed'),(83,6,'General',49,'2026-10-26 04:27:00','Confirmed'),(84,6,'General',13,'2026-10-15 03:54:00','Confirmed'),(85,6,'General',35,'2026-10-12 09:01:00','Confirmed'),(86,6,'General',5,'2026-10-18 18:47:00','Declined'),(87,6,'General',11,'2026-10-17 16:18:00','Cancelled'),(88,7,'General',1,'2026-10-02 11:15:00','Confirmed'),(89,7,'General',40,'2026-10-07 14:23:00','Confirmed'),(90,7,'General',19,'2026-10-03 21:07:00','Confirmed'),(91,7,'General',24,'2026-10-09 19:12:00','Confirmed'),(92,7,'General',20,'2026-10-06 08:57:00','Confirmed'),(93,7,'General',50,'2026-10-09 07:43:00','Confirmed'),(94,7,'General',33,'2026-10-04 07:27:00','Confirmed'),(95,7,'General',7,'2026-10-08 11:26:00','Confirmed'),(96,7,'General',21,'2026-10-07 07:09:00','Confirmed'),(97,7,'General',30,'2026-10-06 04:19:00','Confirmed'),(98,8,'General',8,'2026-10-20 18:40:00','Confirmed'),(99,8,'General',6,'2026-10-21 12:10:00','Confirmed'),(100,8,'General',3,'2026-10-21 20:05:00','Confirmed'),(101,8,'Reader',2,'2026-10-19 09:30:00','Confirmed'),(102,8,'Reader',7,'2026-10-22 15:00:00','Confirmed'),(103,8,'General',12,'2026-10-23 10:45:00','Cancelled'),(104,8,'Reader',45,'2026-10-22 06:26:00','Confirmed'),(105,8,'Reader',22,'2026-10-30 15:31:00','Confirmed'),(106,8,'General',28,'2026-10-20 23:03:00','Confirmed'),(107,8,'General',4,'2026-10-28 18:15:00','Confirmed'),(108,8,'General',24,'2026-10-23 00:42:00','Confirmed'),(109,8,'General',38,'2026-10-26 07:05:00','Confirmed'),(110,8,'General',18,'2026-10-22 17:55:00','Confirmed'),(111,8,'General',39,'2026-10-25 09:44:00','Confirmed'),(112,8,'General',15,'2026-10-28 10:11:00','Confirmed'),(113,8,'General',37,'2026-10-27 13:48:00','Confirmed'),(114,8,'General',43,'2026-10-18 16:27:00','Confirmed'),(115,8,'General',31,'2026-10-25 05:17:00','Confirmed'),(116,8,'General',40,'2026-10-31 12:05:00','Confirmed'),(117,8,'General',20,'2026-11-01 19:04:00','Confirmed'),(118,8,'General',34,'2026-10-26 15:12:00','Confirmed'),(119,8,'General',35,'2026-10-19 23:34:00','Confirmed'),(120,8,'General',48,'2026-10-29 08:47:00','Confirmed'),(121,8,'General',26,'2026-11-04 04:13:00','Confirmed'),(122,8,'General',32,'2026-10-22 20:17:00','Confirmed'),(123,9,'General',15,'2026-10-03 06:00:00','Confirmed'),(124,9,'General',31,'2026-09-28 23:54:00','Confirmed'),(125,9,'General',25,'2026-09-30 02:53:00','Confirmed'),(126,9,'General',32,'2026-09-26 17:37:00','Confirmed'),(127,9,'General',40,'2026-10-02 04:16:00','Confirmed'),(128,9,'General',19,'2026-09-27 10:22:00','Confirmed'),(129,9,'General',7,'2026-10-02 02:26:00','Confirmed'),(130,9,'General',20,'2026-09-30 14:51:00','Confirmed'),(131,9,'General',13,'2026-10-01 03:33:00','Confirmed'),(132,9,'General',36,'2026-10-01 13:34:00','Confirmed'),(133,9,'General',3,'2026-09-29 10:46:00','Confirmed'),(134,9,'General',42,'2026-10-03 00:58:00','Confirmed'),(135,9,'General',34,'2026-09-27 21:27:00','Confirmed'),(136,9,'General',6,'2026-09-28 06:23:00','Confirmed'),(137,9,'General',37,'2026-09-29 12:12:00','Confirmed'),(138,9,'General',39,'2026-09-27 00:38:00','Confirmed'),(139,9,'General',44,'2026-10-01 07:56:00','Confirmed'),(140,9,'General',26,'2026-09-25 11:45:00','Confirmed'),(141,9,'General',14,'2026-10-02 06:50:00','Confirmed'),(142,9,'General',35,'2026-10-02 08:05:00','Confirmed'),(143,9,'General',9,'2026-09-30 14:25:00','Confirmed'),(144,9,'General',33,'2026-10-02 14:23:00','Confirmed'),(145,9,'General',12,'2026-10-04 13:20:00','Waitlisted'),(146,9,'General',49,'2026-10-05 17:45:00','Waitlisted'),(147,9,'General',1,'2026-10-06 21:10:00','Waitlisted'),(148,10,'General',43,'2026-10-29 20:13:00','Confirmed'),(149,10,'General',12,'2026-10-05 20:50:00','Confirmed'),(150,10,'General',45,'2026-10-15 07:10:00','Confirmed'),(151,10,'General',39,'2026-10-24 03:06:00','Confirmed'),(152,10,'General',18,'2026-10-29 12:29:00','Confirmed'),(153,10,'General',38,'2026-10-10 23:04:00','Confirmed'),(154,10,'General',14,'2026-10-14 04:44:00','Confirmed'),(155,10,'General',11,'2026-10-05 15:23:00','Confirmed'),(156,10,'General',34,'2026-10-15 18:21:00','Confirmed'),(157,10,'General',46,'2026-10-29 20:41:00','Confirmed'),(158,10,'General',28,'2026-10-07 11:16:00','Confirmed'),(159,10,'General',49,'2026-10-02 10:35:00','Confirmed'),(160,10,'General',17,'2026-10-08 13:35:00','Confirmed'),(161,10,'General',15,'2026-10-21 00:25:00','Confirmed'),(162,10,'General',1,'2026-10-09 16:25:00','Pending'),(163,10,'General',30,'2026-11-02 07:10:00','Pending'),(164,10,'General',19,'2026-11-02 04:40:00','Pending'),(165,10,'General',40,'2026-11-04 14:20:00','Pending'),(166,10,'General',13,'2026-10-08 04:48:00','Declined'),(167,11,'General',41,'2026-10-17 22:24:00','Confirmed'),(168,11,'General',40,'2026-10-17 08:07:00','Confirmed'),(169,11,'General',23,'2026-10-12 17:39:00','Confirmed'),(170,11,'General',32,'2026-10-16 05:46:00','Confirmed'),(171,11,'General',15,'2026-10-20 12:48:00','Confirmed'),(172,11,'General',28,'2026-10-15 05:04:00','Confirmed'),(173,11,'General',9,'2026-10-16 00:08:00','Confirmed'),(174,11,'General',21,'2026-10-19 03:55:00','Confirmed'),(175,11,'General',29,'2026-10-25 17:25:00','Confirmed'),(176,11,'General',12,'2026-10-18 08:23:00','Confirmed'),(177,11,'General',4,'2026-10-15 11:08:00','Confirmed'),(178,11,'General',38,'2026-10-17 18:08:00','Confirmed'),(179,11,'General',36,'2026-10-23 21:56:00','Confirmed'),(180,11,'General',31,'2026-10-19 00:08:00','Confirmed'),(181,11,'General',30,'2026-10-13 12:48:00','Confirmed'),(182,11,'General',49,'2026-10-12 16:05:00','Confirmed'),(183,11,'General',3,'2026-11-04 19:16:00','Waitlisted'),(184,11,'General',18,'2026-11-02 11:26:00','Waitlisted'),(185,11,'General',43,'2026-11-02 00:12:00','Waitlisted'),(186,12,'General',17,'2026-10-20 21:40:00','Confirmed'),(187,12,'General',31,'2026-10-20 10:44:00','Confirmed'),(188,12,'General',19,'2026-10-15 20:26:00','Confirmed'),(189,12,'General',5,'2026-10-14 00:53:00','Confirmed'),(190,12,'General',49,'2026-10-15 12:59:00','Confirmed'),(191,12,'General',21,'2026-10-20 08:39:00','Confirmed'),(192,12,'General',22,'2026-10-14 12:07:00','Confirmed'),(193,13,'General',1,'2026-10-03 13:00:00','Cancelled'),(194,13,'General',35,'2026-10-11 11:51:00','Confirmed'),(195,13,'General',15,'2026-10-22 16:26:00','Confirmed'),(196,13,'General',23,'2026-10-24 01:42:00','Confirmed'),(197,13,'General',45,'2026-10-01 14:20:00','Confirmed'),(198,13,'General',8,'2026-10-22 03:14:00','Confirmed'),(199,13,'General',16,'2026-10-28 03:45:00','Confirmed'),(200,13,'General',50,'2026-10-13 11:44:00','Confirmed'),(201,13,'General',37,'2026-10-01 18:01:00','Confirmed'),(202,13,'General',3,'2026-10-07 01:13:00','Confirmed'),(203,13,'General',5,'2026-10-03 23:39:00','Confirmed'),(204,13,'General',26,'2026-10-13 05:04:00','Confirmed'),(205,13,'General',13,'2026-10-14 11:44:00','Confirmed'),(206,13,'General',27,'2026-10-04 05:22:00','Cancelled'),(207,14,'General',45,'2026-10-14 21:22:00','Confirmed'),(208,14,'General',46,'2026-10-14 19:27:00','Confirmed'),(209,14,'General',7,'2026-10-18 13:40:00','Confirmed'),(210,14,'General',9,'2026-10-21 17:55:00','Confirmed'),(211,14,'General',3,'2026-10-25 18:01:00','Confirmed'),(212,14,'General',34,'2026-10-15 04:20:00','Confirmed'),(213,14,'General',33,'2026-10-23 05:58:00','Confirmed'),(214,14,'General',37,'2026-10-26 07:59:00','Confirmed'),(215,15,'General',1,'2026-10-04 20:30:00','Declined'),(216,15,'General',20,'2026-10-08 05:54:00','Confirmed'),(217,15,'General',8,'2026-10-07 07:35:00','Confirmed'),(218,15,'General',14,'2026-11-03 04:21:00','Confirmed'),(219,15,'General',30,'2026-10-11 12:27:00','Confirmed'),(220,15,'General',18,'2026-10-12 01:48:00','Confirmed'),(221,15,'General',23,'2026-10-09 11:24:00','Confirmed'),(222,15,'General',3,'2026-10-21 16:56:00','Confirmed'),(223,15,'General',4,'2026-10-07 05:35:00','Confirmed'),(224,15,'General',37,'2026-10-19 02:30:00','Confirmed'),(225,15,'General',22,'2026-11-01 01:01:00','Confirmed'),(226,15,'General',25,'2026-10-21 10:54:00','Confirmed'),(227,15,'General',21,'2026-10-26 10:36:00','Confirmed'),(228,15,'General',35,'2026-10-15 01:05:00','Pending'),(229,15,'General',50,'2026-10-12 07:54:00','Pending'),(230,15,'General',33,'2026-10-25 02:48:00','Pending'),(231,16,'General',24,'2026-10-01 03:44:00','Confirmed'),(232,16,'General',13,'2026-10-05 20:45:00','Confirmed'),(233,16,'General',37,'2026-09-29 13:53:00','Confirmed'),(234,16,'General',18,'2026-10-03 21:10:00','Confirmed'),(235,16,'General',14,'2026-09-28 21:28:00','Confirmed'),(236,16,'General',29,'2026-09-29 05:52:00','Confirmed'),(237,16,'General',43,'2026-09-29 05:44:00','Confirmed'),(238,16,'General',50,'2026-09-28 16:08:00','Confirmed'),(239,16,'General',41,'2026-10-02 15:59:00','Confirmed'),(240,16,'General',39,'2026-10-07 17:47:00','Confirmed'),(241,16,'General',12,'2026-09-30 02:17:00','Confirmed'),(242,16,'General',30,'2026-10-04 18:52:00','Confirmed'),(243,16,'General',27,'2026-10-07 04:09:00','Confirmed'),(244,16,'General',25,'2026-10-05 18:11:00','Confirmed'),(245,16,'General',35,'2026-10-03 18:45:00','Confirmed'),(246,16,'General',32,'2026-10-03 23:48:00','Confirmed'),(247,16,'General',38,'2026-09-30 03:52:00','Confirmed'),(248,16,'General',16,'2026-10-06 07:29:00','Confirmed'),(249,16,'General',15,'2026-10-06 17:26:00','Confirmed'),(250,16,'General',34,'2026-10-06 04:28:00','Confirmed'),(251,16,'General',10,'2026-10-08 15:22:00','Waitlisted'),(252,16,'General',11,'2026-10-10 11:50:00','Waitlisted'),(253,16,'General',7,'2026-10-12 09:14:00','Pending'),(254,16,'General',8,'2026-10-13 16:40:00','Pending'),(255,16,'General',9,'2026-10-14 22:05:00','Pending'),(256,16,'General',2,'2026-10-05 14:49:00','Declined'),(257,16,'General',28,'2026-09-30 18:37:00','Cancelled'),(258,17,'General',2,'2026-10-05 06:00:00','Confirmed'),(259,17,'General',3,'2026-10-05 16:00:00','Confirmed'),(260,17,'General',4,'2026-10-05 07:05:00','Confirmed'),(261,17,'General',6,'2026-10-05 20:30:00','Confirmed'),(262,17,'General',5,'2026-10-07 15:35:00','Confirmed'),(263,18,'Performer',23,'2026-11-02 00:12:00','Confirmed'),(264,18,'Performer',46,'2026-10-18 07:36:00','Confirmed'),(265,18,'Performer',6,'2026-11-03 22:35:00','Confirmed'),(266,18,'General',49,'2026-10-29 20:36:00','Confirmed'),(267,18,'General',21,'2026-11-02 21:14:00','Confirmed'),(268,18,'General',50,'2026-11-03 17:11:00','Confirmed'),(269,18,'General',25,'2026-10-30 11:05:00','Confirmed'),(270,18,'General',34,'2026-10-24 14:11:00','Confirmed'),(271,18,'General',44,'2026-11-02 06:04:00','Confirmed'),(272,19,'General',9,'2026-11-03 11:31:00','Confirmed'),(273,19,'General',29,'2026-11-01 14:21:00','Confirmed'),(274,19,'General',42,'2026-11-03 13:31:00','Confirmed'),(275,19,'General',24,'2026-11-03 00:51:00','Confirmed'),(276,19,'General',32,'2026-11-02 06:49:00','Confirmed'),(277,19,'General',48,'2026-11-02 06:36:00','Confirmed'),(278,21,'Pitching Team',10,'2026-11-03 16:10:00','Confirmed'),(279,21,'General',11,'2026-11-04 07:38:00','Confirmed'),(280,21,'General',47,'2026-11-03 10:02:00','Confirmed'),(281,21,'General',44,'2026-11-03 15:24:00','Confirmed'),(282,21,'General',2,'2026-11-04 02:32:00','Confirmed'),(283,21,'General',8,'2026-11-03 03:26:00','Confirmed'),(284,22,'VIP',39,'2026-11-02 15:49:00','Confirmed'),(285,22,'General',2,'2026-11-02 09:37:00','Confirmed'),(286,22,'General',15,'2026-11-04 07:56:00','Confirmed'),(287,22,'General',36,'2026-11-03 18:20:00','Confirmed'),(288,22,'General',30,'2026-11-04 17:15:00','Confirmed'),(289,23,'General',42,'2026-11-03 21:05:00','Confirmed'),(290,23,'General',6,'2026-11-02 22:18:00','Confirmed'),(291,23,'General',41,'2026-11-02 12:54:00','Confirmed'),(292,23,'General',31,'2026-11-01 18:32:00','Confirmed'),(293,23,'General',7,'2026-11-03 23:43:00','Confirmed'),(294,24,'General',9,'2026-11-02 18:38:00','Confirmed'),(295,24,'General',34,'2026-11-01 09:33:00','Confirmed'),(296,24,'General',49,'2026-11-04 15:48:00','Confirmed'),(297,24,'General',50,'2026-11-04 10:19:00','Confirmed'),(298,24,'General',43,'2026-11-03 02:47:00','Confirmed'),(299,25,'General',19,'2026-11-01 13:06:00','Confirmed'),(300,25,'General',28,'2026-11-04 03:03:00','Confirmed'),(301,25,'General',39,'2026-11-03 07:52:00','Confirmed'),(302,25,'General',8,'2026-11-02 21:57:00','Confirmed'),(303,25,'General',18,'2026-11-03 15:47:00','Confirmed'),(304,20,'General',18,'2026-11-03 03:25:00','Confirmed'),(305,20,'General',40,'2026-11-01 09:26:00','Confirmed'),(306,20,'General',28,'2026-11-02 09:40:00','Pending'),(307,20,'General',36,'2026-11-02 23:07:00','Pending'),(308,20,'General',20,'2026-11-02 09:01:00','Pending'),(309,20,'General',9,'2026-11-01 12:17:00','Pending');
/*!40000 ALTER TABLE `RSVP` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_rsvp_before_insert
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_rsvp_after_insert
AFTER INSERT ON RSVP
FOR EACH ROW
BEGIN
    UPDATE INVITATION
    SET InvitationStatus = 'Accepted'
    WHERE EventID = NEW.EventID
      AND InviteeID = NEW.UserID
      AND InvitationStatus = 'Sent';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `RSVP_ANSWER`
--

DROP TABLE IF EXISTS `RSVP_ANSWER`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `RSVP_ANSWER` (
  `RSVPID` int(11) NOT NULL,
  `QuestionID` int(11) NOT NULL,
  `AnswerText` varchar(500) NOT NULL,
  PRIMARY KEY (`RSVPID`,`QuestionID`),
  KEY `QuestionID` (`QuestionID`),
  CONSTRAINT `rsvp_answer_ibfk_1` FOREIGN KEY (`RSVPID`) REFERENCES `RSVP` (`RSVPID`),
  CONSTRAINT `rsvp_answer_ibfk_2` FOREIGN KEY (`QuestionID`) REFERENCES `RSVP_QUESTION` (`QuestionID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `RSVP_ANSWER`
--

LOCK TABLES `RSVP_ANSWER` WRITE;
/*!40000 ALTER TABLE `RSVP_ANSWER` DISABLE KEYS */;
INSERT INTO `RSVP_ANSWER` VALUES (72,1,'Vegetarian'),(72,2,'Junior'),(72,3,'The robot arm'),(73,1,'None'),(73,2,'Graduate student'),(73,3,'The robot arm'),(74,1,'Gluten free'),(74,2,'First year'),(74,3,'Sumo bots'),(75,1,'No nuts, please'),(75,2,'Senior'),(75,3,'The drone team'),(76,1,'Vegetarian'),(76,2,'Senior'),(76,3,'All of them!'),(77,1,'None'),(77,2,'First year'),(77,3,'All of them!'),(78,1,'Gluten free'),(78,2,'Senior'),(78,3,'All of them!'),(79,1,'Vegetarian'),(79,2,'Junior'),(79,3,'The robot arm'),(80,1,'Halal'),(80,2,'Junior'),(81,1,'Gluten free'),(81,2,'First year'),(81,3,'The drone team'),(82,1,'Halal'),(82,2,'Sophomore'),(82,3,'Sumo bots'),(83,1,'No nuts, please'),(83,2,'Graduate student'),(83,3,'The drone team'),(84,1,'Halal'),(84,2,'Senior'),(85,1,'Vegan'),(85,2,'First year'),(86,1,'None'),(86,2,'Sophomore'),(86,3,'The robot arm'),(87,1,'No nuts, please'),(87,2,'Sophomore'),(87,3,'The robot arm'),(102,4,'Yes'),(103,4,'Yes'),(105,4,'Not sure yet'),(106,4,'No, a favorite poet'),(110,4,'No, a favorite poet'),(112,4,'Not sure yet'),(113,4,'Yes'),(116,4,'Not sure yet'),(118,4,'Yes, two short poems'),(120,4,'No, a favorite poet'),(121,4,'Yes, two short poems'),(122,4,'Not sure yet'),(148,5,'Business and Computer Science'),(149,5,'Computer Science'),(150,5,'Mathematics'),(151,5,'Psychology'),(152,5,'Psychology'),(153,5,'Mathematics'),(154,5,'Economics'),(155,5,'Economics'),(156,5,'Computer Science'),(157,5,'Mathematics'),(158,5,'Data Science'),(159,5,'Computer Science'),(160,5,'Economics'),(161,5,'Business and Computer Science'),(162,5,'Business and Computer Science'),(163,5,'Mathematics'),(164,5,'Psychology'),(165,5,'Mathematics'),(166,5,'Economics'),(167,6,'Yes, two of us'),(168,6,'No, looking for one'),(169,6,'No'),(170,6,'Yes, two of us'),(171,6,'No'),(172,6,'No'),(173,6,'Yes, two of us'),(174,6,'Yes'),(175,6,'No, looking for one'),(176,6,'Yes'),(177,6,'Yes'),(178,6,'No, looking for one'),(179,6,'No'),(180,6,'No'),(181,6,'No'),(182,6,'No, looking for one'),(183,6,'No'),(184,6,'No, looking for one'),(185,6,'Yes'),(215,7,'Vegetarian'),(216,7,'None'),(217,7,'None'),(218,7,'Gluten free'),(219,7,'Vegan'),(220,7,'None'),(221,7,'Vegan'),(222,7,'Gluten free'),(223,7,'None'),(224,7,'Vegetarian'),(225,7,'None'),(226,7,'Gluten free'),(227,7,'No nuts, please'),(228,7,'Vegan'),(229,7,'Halal'),(230,7,'Vegan'),(231,8,'Never, first time!'),(232,8,'A little in high school.'),(233,8,'Yes, I post them online.'),(234,8,'No, but I\'d love to learn.'),(235,8,'Yes, I post them online.'),(236,8,'I write them in my journal.'),(237,8,'Yes, I post them online.'),(238,8,'Never, first time!'),(239,8,'A little in high school.'),(240,8,'A little in high school.'),(241,8,'Yes, a few for a class.'),(242,8,'Never, first time!'),(243,8,'Yes, a few for a class.'),(244,8,'No, but I\'d love to learn.'),(245,8,'A little in high school.'),(246,8,'No, but I\'d love to learn.'),(247,8,'I write them in my journal.'),(248,8,'Never, first time!'),(249,8,'Yes, a few for a class.'),(250,8,'No, but I\'d love to learn.'),(251,8,'Yes, I post them online.'),(252,8,'No, but I\'d love to learn.'),(253,8,'Yes, a few for a class.'),(254,8,'No, but I\'d love to learn.'),(255,8,'I write them in my journal.'),(256,8,'Yes, I post them online.'),(257,8,'A little in high school.'),(258,9,'Gluten free'),(259,9,'None'),(260,9,'Vegetarian'),(261,9,'Vegan'),(262,9,'Vegan'),(263,10,'What the River Kept'),(263,11,'Instagram'),(264,11,'Club newsletter'),(265,11,'Flyer in Kimmel'),(266,10,'Salt and Steam'),(266,11,'Instagram'),(267,10,'Last Train to Brooklyn'),(267,11,'Club newsletter'),(268,10,'Last Train to Brooklyn'),(268,11,'Club newsletter'),(269,10,'What the River Kept'),(269,11,'Flyer in Kimmel'),(270,10,'What the River Kept'),(270,11,'Club newsletter'),(271,10,'Last Train to Brooklyn'),(271,11,'Club newsletter'),(305,12,'Getting a first internship'),(306,12,'Grad school vs industry'),(308,12,'Getting a first internship');
/*!40000 ALTER TABLE `RSVP_ANSWER` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `RSVP_QUESTION`
--

DROP TABLE IF EXISTS `RSVP_QUESTION`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `RSVP_QUESTION` (
  `QuestionID` int(11) NOT NULL AUTO_INCREMENT,
  `EventID` int(11) NOT NULL,
  `QuestionText` varchar(255) NOT NULL,
  `IsRequired` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`QuestionID`),
  KEY `EventID` (`EventID`),
  CONSTRAINT `rsvp_question_ibfk_1` FOREIGN KEY (`EventID`) REFERENCES `EVENT` (`EventID`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `RSVP_QUESTION`
--

LOCK TABLES `RSVP_QUESTION` WRITE;
/*!40000 ALTER TABLE `RSVP_QUESTION` DISABLE KEYS */;
INSERT INTO `RSVP_QUESTION` VALUES (1,6,'Do you have any dietary restrictions?',1),(2,6,'What is your year of study?',1),(3,6,'Which team\'s demo are you most excited about?',0),(4,8,'Will you be reading your own work?',0),(5,10,'What is your major?',1),(6,11,'Do you already have a team?',1),(7,15,'Do you have any dietary restrictions?',1),(8,16,'Have you written haiku before?',1),(9,17,'Do you have any dietary restrictions?',1),(10,18,'If you\'re performing, what\'s the title of your poem?',0),(11,18,'How did you hear about this event?',1),(12,20,'What would you like to talk about at your table?',0);
/*!40000 ALTER TABLE `RSVP_QUESTION` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `TICKET_TYPE`
--

DROP TABLE IF EXISTS `TICKET_TYPE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `TICKET_TYPE` (
  `EventID` int(11) NOT NULL,
  `TypeName` varchar(50) NOT NULL,
  `TypeCapacity` int(11) NOT NULL,
  `Description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`EventID`,`TypeName`),
  CONSTRAINT `ticket_type_ibfk_1` FOREIGN KEY (`EventID`) REFERENCES `EVENT` (`EventID`),
  CONSTRAINT `chk_type_capacity` CHECK (`TypeCapacity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `TICKET_TYPE`
--

LOCK TABLES `TICKET_TYPE` WRITE;
/*!40000 ALTER TABLE `TICKET_TYPE` DISABLE KEYS */;
INSERT INTO `TICKET_TYPE` VALUES (1,'General',50,'Open to everyone'),(2,'General',30,'Laptop required'),(3,'General',32,'Open seating'),(3,'Reader',8,'Read one piece on stage'),(4,'General',60,'Open seating'),(5,'General',100,'Lesson and social dancing'),(6,'General',50,'Standing room and demo access'),(6,'VIP',10,'Front-row seats and meet the team after the demos'),(7,'General',40,'Seat at the chat'),(8,'General',70,'Open seating'),(8,'Reader',10,'Read on stage. Readers and their guests sit in the front rows'),(9,'General',30,'Dinner, performances and dancing'),(10,'General',50,'Panel and Q&A'),(11,'General',16,'Entry to the kickoff and team matching'),(12,'General',30,'Table seat'),(13,'General',50,'Screening seat'),(14,'General',40,'Networking pass'),(15,'General',150,'Dinner and dancing'),(16,'General',20,'Workshop seat'),(17,'General',12,'Dinner seat'),(18,'General',50,'Open seating, vote for your favorite poems'),(18,'Performer',10,'Perform one poem (3 minutes max). Performers and their guests sit in the front rows'),(19,'General',25,'Walk and editing tips'),(20,'General',40,'Brunch seat'),(21,'General',90,'Audience seat'),(21,'Pitching Team',10,'Reserved for teams pitching'),(22,'General',130,'Expo access'),(22,'VIP',20,'Guided tour with the captains'),(23,'General',40,'Class spot'),(24,'General',30,'Drawing spot, materials provided'),(25,'General',40,'Screening seat');
/*!40000 ALTER TABLE `TICKET_TYPE` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `USER`
--

DROP TABLE IF EXISTS `USER`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `USER` (
  `UserID` int(11) NOT NULL AUTO_INCREMENT,
  `UserType` varchar(10) NOT NULL,
  `NetID` varchar(15) DEFAULT NULL,
  `FirstName` varchar(50) NOT NULL,
  `LastName` varchar(50) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `PasswordHash` varchar(255) NOT NULL,
  PRIMARY KEY (`UserID`),
  UNIQUE KEY `Email` (`Email`),
  UNIQUE KEY `NetID` (`NetID`),
  CONSTRAINT `chk_user_type` CHECK (`UserType` in ('NYU','External')),
  CONSTRAINT `chk_user_netid` CHECK (`UserType` = 'NYU' and `NetID` is not null or `UserType` = 'External' and `NetID` is null)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `USER`
--

LOCK TABLES `USER` WRITE;
/*!40000 ALTER TABLE `USER` DISABLE KEYS */;
INSERT INTO `USER` VALUES (1,'NYU','mp4821','Maya','Patel','mp4821@nyu.edu','$2y$10$JtIfJmOwfAgmakoA0HtR0OZjW3WC6.8og9JX6gvama43zzxzJi2Ni'),(2,'NYU','jl7730','Jordan','Lee','jl7730@nyu.edu','$2y$10$oef5c5eByT96VobCrHQbgeQRIq2XfTiEOXBbPjt.2u86urjB8qwv6'),(3,'NYU','ps5512','Priya','Shah','ps5512@nyu.edu','$2y$10$8Fzw3lyB0UUT6J6fH8iFoeLk5Z.KEoAM8yKoR3HlqRQAGSwA9jVI6'),(4,'NYU','cw2209','Chen','Wei','cw2209@nyu.edu','$2y$10$WEAegsgZqPmEfbis2MoZ2uBQLp1enRhY.b9zT7z50cK0HYJq1VZbS'),(5,'External',NULL,'Sam','Rivera','sam.rivera@gmail.com','$2y$10$roPEjbZKScxjAgyvlroZ7.2/ARRTkpu11LFThDiN..B2L.LVQQzkC'),(6,'NYU','ak9012','Ava','Kim','ak9012@nyu.edu','$2y$10$PzocA2cuu7NbeEidAh/Kd.Pf4xVecC7KooqyoLc0OwmwZMzJFjfaG'),(7,'NYU','em3301','Ethan','Moore','em3301@nyu.edu','$2y$10$42KBNMBK/D/8NzeWDqlEC.Ne7/ys/S5XQgWqPGpdttXyl/PvTGiVa'),(8,'NYU','lh4410','Lina','Haddad','lh4410@nyu.edu','$2y$10$xUY2XIDyxJjHnjMdIqgkqu.uClXTWrfFwF2wcDrchq0pu9J2r9OBS'),(9,'NYU','mg7781','Marcus','Green','mg7781@nyu.edu','$2y$10$nOOI61SS55p/uHi1mjkHeOWEuTk3n9qb.xDgGg/S6h4r/k/gF6RK6'),(10,'NYU','zc2290','Zoe','Clark','zc2290@nyu.edu','$2y$10$IAwYLHtPYh8Gq0UhBCD5bOpVdQjj/fXobwZ8BxYsIzTQ9KpTBGr4e'),(11,'NYU','oa6618','Omar','Ali','oa6618@nyu.edu','$2y$10$ZYrHAEjPWdLIduPwI/D8yOI.DBUJXC7.aHNWl8MFLBHJHJDXomlFO'),(12,'NYU','rc5530','Riley','Chen','rc5530@nyu.edu','$2y$10$jMzZFb18XhFlW7F5CkXK2.N3ZnVR.4mu.fn.ECB8nYZ8e3cRpXLGq'),(13,'NYU','dc3104','Daniel','Cho','dc3104@nyu.edu','$2y$10$gZX2A2Hi/zwTKFlvlN80J.5vw9MNJ6RETkgww9AVhNpam.dGs/2s2'),(14,'NYU','gl2817','Grace','Liu','gl2817@nyu.edu','$2y$10$K5tcv2ZAeivk/qb4/013KuNyrLKWBPz68W1KmKo2fDSGuQ8GeaMw6'),(15,'NYU','ab6640','Ava','Brooks','ab6640@nyu.edu','$2y$10$uV8DLaK0csIdgtg9rLEBc.nkMbeuzOCV0ONUjTAovb/2H/YBh0EUm'),(16,'NYU','bc1975','Ben','Carter','bc1975@nyu.edu','$2y$10$.JdkRS/KaXnawgQDt.079.gRJfupmiQ6bWOY3XG2RaeGeBDeW3xOO'),(17,'NYU','hs4023','Hana','Sato','hs4023@nyu.edu','$2y$10$0Xc.6SW.BHKTYFq6Kr22/uo6T8rhpVweV8coyO.cC1EebBeNlP5hG'),(18,'NYU','lg5561','Leo','Grant','lg5561@nyu.edu','$2y$10$7Gizol65UgtMUlw2XhPQW.U5i5m8WvQIErCkuRUObu9E/d1NF6Bxa'),(19,'NYU','ro3348','Ruth','Okafor','ro3348@nyu.edu','$2y$10$4oJnJ4VoK2gcGkPI5N/ogumvrbJmPS1wa3JOtNo1mMoK/CJf3Xa1i'),(20,'NYU','kp2291','Kevin','Park','kp2291@nyu.edu','$2y$10$tn9i1usuImGAtdR2ieLd9.NRI82MFJYWnke0U.dLVTsaTSq6JCbVS'),(21,'NYU','ar7012','Aisha','Rahman','ar7012@nyu.edu','$2y$10$B.lW6gY3hH36b/dBiIJnquzVufgpr7ZQWE1K.7bdlFpG1YXTUtNoW'),(22,'NYU','nk4455','Noah','Kim','nk4455@nyu.edu','$2y$10$FPpdtu1omiG2HVCp2fxTj.41jzZGnpC4WLeUILD5o22D3OzJdkQhK'),(23,'NYU','sm8820','Sofia','Martinez','sm8820@nyu.edu','$2y$10$tfg.Gi0KnIsH.ubmK2tsoeNY95w2ENpD6VWEvpfAIe8klbEjO3sAu'),(24,'NYU','cm6134','Carlos','Mendez','cm6134@nyu.edu','$2y$10$40h1O.bsO/5s6XwP1dF63OXFA4J35g7cDw45CWLdQwhHwwnG4fMsC'),(25,'NYU','yt2718','Yuki','Tanaka','yt2718@nyu.edu','$2y$10$OjA.USv9ouXjwpcGDP2PtuqM7Xt3SURhjm.rIBUy7QABl.wYKPPZi'),(26,'NYU','jw5093','Jamal','Wright','jw5093@nyu.edu','$2y$10$2AlXsMk/dK2jJVOmSPx4JOw/aYXVyINsjc4w06ZRzNlWDUw/m128.'),(27,'NYU','nr3867','Nina','Rossi','nr3867@nyu.edu','$2y$10$8DcWheMtU0VbWsrlWxmhuu78ZcWiIT8dtNXpGl5QszDz4rUuz7MEq'),(28,'NYU','am9154','Arjun','Mehta','am9154@nyu.edu','$2y$10$JCCaz5S2.AtzJRawQBN4IukVdf6h06haoKeBHEbKWfQlUTJ1AOt26'),(29,'NYU','fn2276','Fatima','Noor','fn2276@nyu.edu','$2y$10$llLPdECYXWi3J7dtMXLAZ..fFjydPIV6FJ6xqy2LMrbhWvlnJI/y2'),(30,'NYU','ls4408','Lucas','Silva','ls4408@nyu.edu','$2y$10$fqbc.7ukbWp8s5qrao60b.csLcEwe8f6HuBnL72AYpKiCXrN0RKXC'),(31,'NYU','ej6612','Emma','Johnson','ej6612@nyu.edu','$2y$10$TBO0YwHVdDrAyK0Jzzhtce7qwyBGemsfe3haRydL8A.KKvr2YJGpS'),(32,'NYU','md3390','Mateo','Diaz','md3390@nyu.edu','$2y$10$hzSLVJYwrNEU8x1pr4klg.5J80HbMD/h.QU0/60zJ8gSHOackCHUK'),(33,'NYU','ob7721','Olivia','Brown','ob7721@nyu.edu','$2y$10$OzaqVyApddt6Y7tm56xVP.YZS1fafVk06NYUNM9cYumBTB5OJe8CC'),(34,'NYU','ic2045','Isaac','Cohen','ic2045@nyu.edu','$2y$10$SDvMeuAXmJYufw5a8Tr6zubgXSzEWcOXh9FxmSmjJetHGYpQ0hICC'),(35,'NYU','mw5587','Mia','Wong','mw5587@nyu.edu','$2y$10$APrj0BOPAV9JBWptNuF5au6tIYtLdPa7mNlwYM8vkwQSlxYz3WTPW'),(36,'NYU','th1839','Tariq','Hassan','th1839@nyu.edu','$2y$10$90IElSKXb6ZltdZun5XHsuzb2afrKuxUXiosdsCVQDLdeYhbfk2d.'),(37,'NYU','cn6602','Chloe','Nguyen','cn6602@nyu.edu','$2y$10$wjMK7.D7juo28NTeFuEb9.5u.V02kNCHSTj6MSy6SGkWd2P2YHUB.'),(38,'NYU','ro7290','Ryan','O\'Brien','ro7290@nyu.edu','$2y$10$MddFTb6mrS8K/XcBvF1if.2bB6MMV7wqyLHhLkK96mHHl4zY55iI6'),(39,'NYU','sk3916','Sara','Kowalski','sk3916@nyu.edu','$2y$10$1BTzeGRub9eK.hNRlT7iI.DmuF8qkwL1swja8A4Ompw2NkUH02nBC'),(40,'NYU','vh8427','Victor','Huang','vh8427@nyu.edu','$2y$10$qIXu3HAuJ3jjhniSnb5j/ues7fT856U2YwmwRqU2JNH0ryxqE2WvO'),(41,'NYU','la2593','Layla','Ahmed','la2593@nyu.edu','$2y$10$I82N7cCFTfXdsGeaamuzwu4Up.i8eoUjfTs.SIoX3Y8TfxJ3k0pQC'),(42,'NYU','jp7704','Jin','Park','jp7704@nyu.edu','$2y$10$kBSfObQp487pORMYH/mCA.3mfNiS47TpEvS7l9vn8h5411HJNYeC2'),(43,'NYU','ao5182','Amara','Okeke','ao5182@nyu.edu','$2y$10$FWBhOOE4Uxp6GZTuirNhPeotTk4Yd0s3EjFaNcBHgpIxwXUdxwGXa'),(44,'NYU','dt2961','Diego','Torres','dt2961@nyu.edu','$2y$10$zBTHYjm98kTdPYV//IggvuRHLqIjmpCoNNhQiogW6u2n5Hi/1o0TW'),(45,'External',NULL,'Hannah','Weiss','hannah.weiss@gmail.com','$2y$10$5R/1sMU1o1H0k2U5vNrlneCoOk7Rw9hualwS.prm9bETlAx7q3WUm'),(46,'External',NULL,'Marco','Bianchi','marco.bianchi@outlook.com','$2y$10$4pd9np/ZsN5xTUO2qUd2UOFkVw/HEol97a2HWResWDklU471koqni'),(47,'External',NULL,'Tyler','Brooks','tyler.brooks@yahoo.com','$2y$10$PcAn5uonL1x0YcZC8fleJO5uI9aM0eBVMnjKsjVLTJ0vyuE7dR6p.'),(48,'External',NULL,'Elena','Petrova','elena.petrova@gmail.com','$2y$10$QbgY4BoHDIOxaW48VQkWYObIPXcu8YuVMOq1r7E2mDCDOv1XNe.hW'),(49,'NYU','kb4417','Kai','Bennett','kb4417@nyu.edu','$2y$10$sGD83oBaP3vjVsohUySLh.yJ/F1VfyxhO5lz0NCsAyvo3BW0zmLqi'),(50,'NYU','pr6025','Paula','Reyes','pr6025@nyu.edu','$2y$10$SV5j/1.dhN4CHuj.GMmXt.p.MvBCIg4py1PCaiTfTFMkN1dtV7HK6');
/*!40000 ALTER TABLE `USER` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `USER_PHONE`
--

DROP TABLE IF EXISTS `USER_PHONE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `USER_PHONE` (
  `UserID` int(11) NOT NULL,
  `PhoneNumber` varchar(20) NOT NULL,
  PRIMARY KEY (`UserID`,`PhoneNumber`),
  CONSTRAINT `user_phone_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `USER` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `USER_PHONE`
--

LOCK TABLES `USER_PHONE` WRITE;
/*!40000 ALTER TABLE `USER_PHONE` DISABLE KEYS */;
INSERT INTO `USER_PHONE` VALUES (1,'(212) 555-0143'),(1,'(917) 555-0188'),(2,'(646) 555-0112'),(3,'(917) 555-0175'),(5,'(718) 555-0190'),(6,'(347) 555-0123'),(7,'(212) 555-0167'),(9,'(646) 555-0131'),(13,'(917) 555-0104'),(13,'+971 50 555 0142'),(14,'(212) 555-0158'),(15,'(347) 555-0186'),(20,'(646) 555-0149'),(21,'(917) 555-0137'),(22,'(212) 555-0199'),(23,'(718) 555-0115'),(26,'(646) 555-0172'),(28,'+91 98 5550 1234'),(31,'(917) 555-0128'),(36,'+971 55 555 0187'),(42,'(347) 555-0161'),(45,'(201) 555-0144'),(46,'+39 333 555 0101'),(48,'(718) 555-0153');
/*!40000 ALTER TABLE `USER_PHONE` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `VENUE`
--

DROP TABLE IF EXISTS `VENUE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `VENUE` (
  `VenueID` int(11) NOT NULL AUTO_INCREMENT,
  `VenueName` varchar(100) NOT NULL,
  `Building` varchar(100) NOT NULL,
  `Floor` int(11) NOT NULL,
  `RoomNumber` varchar(20) DEFAULT NULL,
  `MaxCapacity` int(11) NOT NULL,
  PRIMARY KEY (`VenueID`),
  CONSTRAINT `chk_venue_capacity` CHECK (`MaxCapacity` > 0)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `VENUE`
--

LOCK TABLES `VENUE` WRITE;
/*!40000 ALTER TABLE `VENUE` DISABLE KEYS */;
INSERT INTO `VENUE` VALUES (1,'370 Jay St Room 220','370 Jay St',2,'220',60),(2,'370 Jay St Auditorium','370 Jay St',1,NULL,200),(3,'Leslie eLab','Leslie eLab',1,NULL,40),(4,'Kimmel Room 405','Kimmel Center',4,'405',80),(5,'Rosenthal Pavilion','Kimmel Center',10,NULL,300),(6,'Bobst Room 220','Bobst Library',2,'220',50),(7,'Kimmel Room 914','Kimmel Center',9,'914',40),(8,'Paulson Center Room 201','Paulson Center',2,'201',70),(9,'Silver Center Room 207','Silver Center',2,'207',45),(10,'Tisch Hall Room 200','Tisch Hall',2,'200',120),(11,'Third North Lounge','Third North',1,NULL,60),(12,'Kimmel Room 802','Kimmel Center',8,'802',30);
/*!40000 ALTER TABLE `VENUE` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'rsvp_db'
--
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_spots_taken` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_spots_taken`(p_event_id INT) RETURNS int(11)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_type_spots_taken` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_type_spots_taken`(p_event_id INT, p_type_name VARCHAR(50)) RETURNS int(11)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cancel_rsvp` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancel_rsvp`(IN p_rsvp_id INT, IN p_user_id INT)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-07  4:41:13
