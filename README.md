<div align="center">

# IVY

Zig backend for tree

</div>

> [!WARNING]
> Ivy is still currently in development

## Running

```sh
zig build -Doptimize=ReleaseFast
```

## User requirements

### Ivy
[x] Get songs           GET api/song/get            JSON
[] Play song            GET api/song/play           JSON
[x] Get songs meta      GET api/song/meta           JSON
[] Create song          POST api/song/create        JSON
[] Play beat            POST api/beat/play          JSON
[] Create tree          POST api/tree/create        JSON
[x] Get trees           GET api/tree/get            JSON
[x] Get tree metadata   GET api/tree/meta           JSON
[] Receive Config File  GET api/config              JSON
[] Send Config File     POST api/config             JSON


### Holly
[] Store songs and tree
[] WebAPI
[] Play selected song on lights
[] Receieve new songs
[] Display one beat
[] Configuration file

#### Song Json Example
```json
{
    "id": "int",
    "name": "string",
    "author": "string",
    "beat_count": "int",
    "beats": [
        [ "rgba": "string" ]
    ]
}
```

#### Tree Json Example
```json
{
    "id": "int",
    "name": "string",
    "points":
        [ { "x": "int", "y": "int", "z": "int" } ]
}
```

### Create Database

```sql
create user 'beech'@'localhost' identified by 'password';
grant all privileges on *.* to 'beech'@'localhost' with grant option;
flush privileges;
create database beech;
```
