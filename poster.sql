CREATE TABLE `rex_notes` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) DEFAULT NULL,
    `properties` text NOT NULL,
    `propid` int(11) NOT NULL,
    `proptype` varchar(50) DEFAULT NULL,
    `title` varchar(50) DEFAULT NULL,
    `note` text NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
