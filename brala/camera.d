module brala.camera;

private {
    import gl3n.linalg;
    import gl3n.math;
    
    import brala.engine : BraLaEngine;
}


// Refering to https://github.com/mitsuhiko/webgl-meincraft/blob/master/src/camera.coffee
struct Camera {
    BraLaEngine engine;    
    vec3 position = vec3(0.0f, 0.0f, 0.0f);
    vec3 forward = vec3(0.0f, 0.0f, -1.0f);
    float fov = 45.0f;
    float near = 1.0f;
    float far = 400.0f;
    vec3 up = vec3(0.0f, 1.0f, 0.0f);
    
    this(BraLaEngine engine) {
        this.engine = engine;
    }
    
    this(BraLaEngine engine, vec3 position, float fov, float near, float far) {
        this.engine = engine;
        this.position = position;
        this.fov = fov;
        this.near = near;
        this.far = far;
    }
     
    void look_at(vec3 pos) {
        forward = (pos - position).normalized;
    }
    
    Camera rotatex(float angle) { // degrees
        mat4 rotmat = quat.axis_rotation(up, radians(-angle)).to_matrix!(4,4);
        forward = vec3(rotmat * vec4(forward, 1.0f)).normalized;
        return this;
    }

    Camera rotatey(float angle) { // degrees
        vec3 vcross = cross(up, forward);
        mat4 rotmat = quat.axis_rotation(vcross, radians(angle)).to_matrix!(4,4);
        forward = vec3(rotmat * vec4(forward, 1.0f)).normalized;
        return this;
    }
    
    Camera move_forward(float delta) {
        position = position + forward*delta;
        return this;
    }
    
    Camera move_backward(float delta) {
        position = position - forward*delta;
        return this;
    }
    
    @property mat4 camera() {
        vec3 target = position + forward;
        return mat4.look_at(position, target, up);
    }
    
    void apply() {
        engine.proj = mat4.perspective(engine.viewport.x, engine.viewport.y, fov, near, far);
        engine.view = camera;
    }
}