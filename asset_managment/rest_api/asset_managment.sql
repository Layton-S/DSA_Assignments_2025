-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Sep 21, 2025 at 09:38 PM
-- Server version: 9.1.0
-- PHP Version: 7.4.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `asset_managment`
--

-- --------------------------------------------------------

--
-- Table structure for table `assets`
--

DROP TABLE IF EXISTS `assets`;
CREATE TABLE IF NOT EXISTS `assets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assetTag` varchar(100) NOT NULL,
  `name` varchar(255) NOT NULL,
  `faculty` varchar(255) DEFAULT NULL,
  `department` varchar(255) DEFAULT NULL,
  `status` int DEFAULT NULL,
  `acquiredDate` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `assetTag` (`assetTag`),
  KEY `status` (`status`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `assets`
--

INSERT INTO `assets` (`id`, `assetTag`, `name`, `faculty`, `department`, `status`, `acquiredDate`) VALUES
(1, 'PRINT_001', '3D Printer', 'Computing & Informatics', 'Software Engineering', 1, '2024-03-10'),
(2, 'SERVER_001', 'High-Performance Server', 'Computing & Informatics', 'Information Systems', 1, '2023-08-15'),
(3, 'EQ-003', 'Spectrometer', 'Health & Applied Sciences', 'Chemistry', 2, '2022-05-20'),
(4, 'EQ-004', 'Minibus', 'Facilities Directorate', 'Transport', 1, '2021-01-12'),
(5, 'EQ-005', 'Projector', 'Humanities', 'History', 3, '2019-09-05');

-- --------------------------------------------------------

--
-- Table structure for table `components`
--

DROP TABLE IF EXISTS `components`;
CREATE TABLE IF NOT EXISTS `components` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assetId` int DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `description` text,
  PRIMARY KEY (`id`),
  KEY `assetId` (`assetId`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `components`
--

INSERT INTO `components` (`id`, `assetId`, `name`, `description`) VALUES
(1, 1, 'Extruder Motor', 'Drives the filament for printing'),
(2, 1, 'Heated Bed', 'Maintains temperature for proper adhesion'),
(3, 2, 'Hard Drive', '2TB NVMe storage'),
(4, 2, 'Power Supply', '1200W redundant PSU'),
(5, 3, 'Lens', 'Precision optical lens for spectrometry'),
(6, 4, 'Engine', '2.5L Turbo Diesel Engine'),
(7, 5, 'Lamp', 'Main projector lamp unit');

-- --------------------------------------------------------

--
-- Table structure for table `schedules`
--

DROP TABLE IF EXISTS `schedules`;
CREATE TABLE IF NOT EXISTS `schedules` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assetId` int DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `frequency` varchar(100) DEFAULT NULL,
  `nextDue` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `assetId` (`assetId`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `schedules`
--

INSERT INTO `schedules` (`id`, `assetId`, `name`, `frequency`, `nextDue`) VALUES
(1, 1, 'Quarterly Maintenance', 'Quarterly', '2025-06-01'),
(2, 2, 'Server Checkup', 'Monthly', '2025-09-10'),
(3, 3, 'Calibration', 'Yearly', '2025-03-01'),
(4, 4, 'Engine Service', 'Bi-Annual', '2025-07-15'),
(5, 5, 'Lamp Replacement', 'Yearly', '2024-11-20');

-- --------------------------------------------------------

--
-- Table structure for table `status`
--

DROP TABLE IF EXISTS `status`;
CREATE TABLE IF NOT EXISTS `status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `status`
--

INSERT INTO `status` (`id`, `name`) VALUES
(1, 'ACTIVE'),
(2, 'UNDER_REPAIR'),
(3, 'DISPOSED');

-- --------------------------------------------------------

--
-- Table structure for table `task`
--

DROP TABLE IF EXISTS `task`;
CREATE TABLE IF NOT EXISTS `task` (
  `id` int NOT NULL AUTO_INCREMENT,
  `workOrderId` int DEFAULT NULL,
  `description` text,
  `done` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `workOrderId` (`workOrderId`)
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `task`
--

INSERT INTO `task` (`id`, `workOrderId`, `description`, `done`) VALUES
(1, 1, 'Check extruder nozzle', 0),
(2, 1, 'Replace filament', 1),
(3, 2, 'Clean dust from fans', 1),
(4, 2, 'Apply new thermal paste', 0),
(5, 3, 'Recalibrate optical sensor', 0),
(6, 4, 'Order new tires', 1),
(7, 4, 'Replace all tires', 0),
(8, 5, 'Purchase new lamp unit', 1),
(9, 5, 'Install lamp and test projector', 0);

-- --------------------------------------------------------

--
-- Table structure for table `workorder`
--

DROP TABLE IF EXISTS `workorder`;
CREATE TABLE IF NOT EXISTS `workorder` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assetId` int DEFAULT NULL,
  `description` text,
  `status` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `assetId` (`assetId`),
  KEY `status` (`status`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `workorder`
--

INSERT INTO `workorder` (`id`, `assetId`, `description`, `status`) VALUES
(1, 1, 'Printer not extruding filament properly', 2),
(2, 2, 'Server overheating issue', 2),
(3, 3, 'Spectrometer producing inaccurate results', 2),
(4, 4, 'Minibus needs tire replacement', 1),
(5, 5, 'Projector lamp burned out', 2);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
