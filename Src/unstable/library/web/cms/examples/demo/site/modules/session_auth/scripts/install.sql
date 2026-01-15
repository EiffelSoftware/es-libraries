
CREATE TABLE auth_session (
   `uid` INTEGER PRIMARY KEY CHECK(`uid`>=0),
   `access_token` VARCHAR(64) UNIQUE NOT NULL,
   `created` DATETIME NOT NULL
);

