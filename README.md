<div align="center">

# IVY

Zig backend for tree

</div>

> [!WARNING]
> Ivy is still currently in active development<br>
> Some features may not work properly

## Dependencies

- [zig (0.13.0)](https://github.com/tristanisham/zvm)
- [rpi_ws281x](https://github.com/jgarff/rpi_ws281x)

## Build and run

```sh
zig build -Doptimize=ReleaseFast && ./zig-out/bin/ivy
```

## User requirements

### Ivy
- [x] Get songs           GET api/song/get            JSON <br>
- [ ] Play song            GET api/song/play           JSON <br>
- [x] Get songs meta      GET api/song/meta           JSON <br>
- [ ] Create song          POST api/song/create        JSON <br>
- [ ] Play beat            POST api/beat/play          JSON <br>
- [x] Create tree          POST api/tree/create        JSON <br>
- [x] Get trees           GET api/tree/get            JSON <br>
- [x] Get tree metadata   GET api/tree/meta           JSON <br>
- [ ] Receive Config File  GET api/config              JSON <br>
- [ ] Send Config File     POST api/config             JSON <br>

- [ ] Make sure all mem is freed

### Holly
- [ ] Store songs and tree <br>
- [ ] WebAPI <br>
- [ ] Play selected song on lights <br>
- [ ] Receieve new songs <br>
- [ ] Display one beat <br>
- [ ] Configuration file <br>

#### Song Json Example
```json
{
    "id": "int",
    "name": "string",
    "author": "string",
    "beats": [
        [ "rgba": "string" ]
    ]
}
```

#### Song Creation Request Example
```json

{
    "name": "string",
    "author": "string",
    "beats": [ [ "rgba": "string" ] ]
}
```

#### Tree Json Example
```json
{
    "id": "int",
    "name": "string",
    "points": [ { "x": "int", "y": "int", "z": "int" } ]
}
```

### Create Database

```sql
create user 'beech'@'localhost' identified by 'password';
grant all privileges on *.* to 'beech'@'localhost' with grant option;
flush privileges;
create database beech;
```
