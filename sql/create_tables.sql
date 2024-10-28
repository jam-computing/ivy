-- Song should have name and author
-- Should also have a list of list of rgb values
create table song (
    id int unsigned primary key auto_increment,
    name varchar(255),
    author varchar(255),
    beats JSON
);

-- Tree should have a unique name
-- Should also have a json list of NORMALISED point coordinates
create table tree (
    id int unsigned primary key auto_increment,
    name varchar(255) unique,
    points JSON,
);
