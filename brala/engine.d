module brala.engine;

private {
    import glamour.gl;
    import glamour.shader : Shader;
    import glamour.texture : ITexture;
    import glamour.sampler : Sampler;
    
    import derelict.glfw3.glfw3;
    
    import gl3n.linalg;
    
    import brala.timer : Timer, TickDuration;
    import brala.resmgr : ResourceManager;
    
    debug import std.stdio : writefln;
}


class BraLaEngine {
    protected vec2i _viewport = vec2i(0, 0);
    Timer timer;
    ResourceManager resmgr;
    void* window;

    @property vec2i viewport() {
        return _viewport;
    }
    
    immutable GLVersion opengl_version;
    
    mat4 model;
    mat4 view;
    mat4 proj;
    
    @property mat4 mvp() {
        return proj * view * model;
    }
    
    @property mat4 mv() {
        return view * model;
    }
    
    protected Shader _current_shader = null;
    protected ITexture _current_texture = null;
    protected Sampler _current_sampler = null;
    Sampler[ITexture] samplers;
    
    @property Shader current_shader() { return _current_shader; }
    @property void current_shader(Shader shader) {
        if(_current_shader !is null) _current_shader.unbind();
        _current_shader = shader;
        _current_shader.bind();
    }

    @property ITexture current_texture() { return _current_texture; }
    @property void current_texture(ITexture texture) {
        _current_texture = texture;
        _current_texture.activate();
        _current_texture.bind();
        if(Sampler* sampler = _current_texture in samplers) {
            _current_sampler = *sampler;
            _current_sampler.bind(_current_texture);
        }
    }
    
    this(void* window, int width, int height, GLVersion glv) {
        timer = new Timer();
        resmgr = new ResourceManager();
        
        opengl_version = glv;
        _viewport = vec2i(width, height);
        
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);
        glEnable(GL_CULL_FACE);
        version(none) {
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }
    }
    
    void mainloop(bool delegate(TickDuration) callback) {
        bool stop = false;
        timer.start();
        
        TickDuration last;
        debug TickDuration lastfps = TickDuration(0);
        
        while(!stop) {
            TickDuration delta_ticks = (timer.get_time() - last);

            stop = callback(delta_ticks);
        
            debug {
                TickDuration t = timer.get_time();
                if((t-lastfps).to!("seconds", float) > 0.5) {
                    writefln("Frame-Time: %s ms", (t-last).to!("msecs", float));
                    lastfps = t;
                }
            }
            
            last = timer.get_time();

            glfwSwapBuffers(window);
            glfwPollEvents();
        }
        
        TickDuration ts = timer.stop();
        debug writefln("Mainloop ran %f seconds", ts.to!("seconds", float));
    }
    
    void use_shader(Shader shader) {
        current_shader = shader;
    }
    
    void use_shader(string id) {
        current_shader = resmgr.get!Shader(id);
    }
    
    void flush_uniforms() {
        flush_uniforms(_current_shader, true);
    }
    
    void flush_uniforms(Shader shader, bool bound = false) {
        if(!bound) shader.bind();
        
        shader.uniform("viewport", viewport);
        shader.uniform("model", model);
        shader.uniform("view", view);
        shader.uniform("proj", proj);
    }

    void use_texture(ITexture texture) {
        current_texture = texture;
    }

    void use_texture(string id) {
        current_texture = resmgr.get!ITexture(id);
    }

    void set_sampler(ITexture tex, Sampler s) {
        samplers[tex] = s;
    }
    
    void set_sampler(string tex_id, Sampler s) {
        samplers[resmgr.get!ITexture(tex_id)] = s;
    }
}