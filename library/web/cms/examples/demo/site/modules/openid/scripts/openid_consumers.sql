
CREATE TABLE openid_consumers(
   `cid` INTEGER PRIMARY KEY CHECK(`cid`>=0),
   `name` VARCHAR(255) UNIQUE NOT NULL,
   `endpoint`  VARCHAR (255) NOT NULL
   );

