# IVY
Zig backend for tree

## Storing songs

Each song is a list of "beats".

Each beat is just a lot of bytes.
Each set of 4 bytes map to a rgba value.

## User requirements

### Holly
- Create Tree
- Create Beat
- Get songs -           GET api/song/get            JSON
- Play song -           GET api/song/play           JSON
- Send beat -           POST api/beat/play
- Send tree -           POST api/tree/create
- Send song -           POST api/song/create
- Receive Config File   GET api/config
- Send Config File      POST api/config

### Ivy
- Store songs and tree
- WebAPI
- Play selected song on lights
- Receieve new songs
- Display one beat
- Configuration file

#### Song Json Example
```json
{
    "id": "int",
    "name": "string",
    "author": "string",
    "beat_count": "int",
    "beats": {
        [ "red": "int", "green": "int", "blue": "int", "alpha": "int" ]
    }
}
```

#### Tree Json Example
```json
{
    "id": "int",
    "name": "string",
    "points": {
        [ "x": "int", "y": "int", "z": "int" ]
    }
}
```
