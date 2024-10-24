delete from tree;
delete from song;
insert into tree (name, points) values (
    "Tree 001",
    '[{"x": 0, "y": 0, "z": 0}, {"x": 1, "y": 1, "z": 1}]'
);
insert into tree (name, points) values (
    "Matthew Tree",
    '[{"x": 9, "y": 4, "z": 2}, {"x": 0, "y": 10, "z": 4}, {"x": -5, "y": 17, "z": 6},{"x": 3, "y": 13, "z": 9},{"x": 3, "y": 2, "z": 4}]'
);

insert into song(name, author, beat_count, beats) values (
    "green", "gracey", 2, '[ [ "00ff00ff" ], [ "0000ffff ] ]'
);
