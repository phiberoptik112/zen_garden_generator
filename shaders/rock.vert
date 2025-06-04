attribute vec3 VertexNormal;
attribute vec3 RockPosition;

varying vec4 RockTexCoord;
varying vec3 VaryingNormal;
varying vec3 VaryingPosition;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    RockTexCoord = vertex_position;
    VaryingNormal = VertexNormal;
    VaryingPosition = RockPosition;
    return transform_projection * vertex_position;
}