
CREATE TABLE openid_items (
   `uid` INTEGER PRIMARY KEY CHECK(`uid`>=0),
   `identity` TEXT UNIQUE NOT NULL,
   `created` DATETIME NOT NULL
   );

