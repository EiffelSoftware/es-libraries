CREATE TABLE user_profiles(
  `uid` INTEGER NOT NULL,
  `key` VARCHAR(255) NOT NULL,
  `value` TEXT,
  CONSTRAINT PK_uid_key PRIMARY KEY (`uid`,`key`)
);
