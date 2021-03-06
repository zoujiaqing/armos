module armos.app.basewindow;

import derelict.opengl3.gl;
import armos.events;
import armos.math;
import armos.app;

/++
armosで用いるWindowsの雛形となるinterfaceです．新たにWindowを実装する際はこのinterfaceを継承することでrunnerから実行できます．
+/
interface Window{
    public{
        /++
            Windowsが実行するイベントを表すプロパティです．
            +/
            armos.events.CoreEvents events();

        /++
            サイズを返すプロパティです．
            +/
            armos.math.Vector2i size();

        /++
            イベントが発生している場合，登録されたイベントを実行します
            +/
            void pollEvents();

        /++
            Windowを更新します．
            +/
            void update();

        /++
            Windowを閉じます．
            +/
            void close();

        /++
            Windowがフレームの最後に閉じる場合trueになります．
            +/
            bool shouldClose();

        /++
            Windowのアスペクト比を表します
            +/
            float aspect();

        /++
            Windowのタイトル文字列のプロパティです．
            +/
            string name();

        /++
            Windowのタイトル文字列のプロパティです．
            +/
            void name(in string str);
    }//public
}

mixin template BaseWindow(){
    public{
        /++
            +/
            bool shouldClose(){return _shouldClose;}

        /++
            +/
            string name(){return _name;}

        /++
            +/
            void name(in string str){_name = str;}

        /++
            +/
            void initEvents(armos.app.baseapp.BaseApp app){
                _app = app;
                _coreEvents= new armos.events.CoreEvents;
                assert(_coreEvents);

                armos.events.addListener(_coreEvents.setup, app, &app.setup);
                armos.events.addListener(_coreEvents.update, app, &app.update);
                armos.events.addListener(_coreEvents.draw, app, &app.draw);
                armos.events.addListener(_coreEvents.keyPressed, app, &app.keyPressed);
                armos.events.addListener(_coreEvents.mouseMoved, app, &app.mouseMoved);
                armos.events.addListener(_coreEvents.mouseDragged, app, &app.mouseDragged);
                armos.events.addListener(_coreEvents.mouseReleased, app, &app.mouseReleased);
                armos.events.addListener(_coreEvents.mousePressed, app, &app.mousePressed);
            }

        /++
            +/
            armos.events.CoreEvents events(){
                assert(_coreEvents);
                return _coreEvents;
            }

        /++
            +/
            float aspect(){
                if(size[1]==0){
                    return 0;
                }else{
                    return cast(float)size[0]/cast(float)size[1];
                }

            }
    }//public

    private{
        armos.app.baseapp.BaseApp _app;
        armos.events.CoreEvents _coreEvents;
    }//private

    protected{
        bool _shouldClose = false;
        string _name = "";
        armos.math.Vector2f _windowSize;
    }//protected
}

/++
SDLを利用したWindowです．
Deprecated: GLFWWindowの使用が推奨されています．
+/
class SDLWindow : Window{
    import derelict.sdl2.sdl;
    mixin BaseWindow;

    private SDL_Window* window;
    private SDL_GLContext glcontext;

    this(ref armos.app.BaseApp apprication){
        DerelictGL.load();
        DerelictSDL2.load();

        SDL_Init(SDL_INIT_VIDEO);
        window = SDL_CreateWindow(
                cast(char*)_name,
                SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                800, 600,
                SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE
                );

        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);

        glcontext = SDL_GL_CreateContext(window);

        DerelictGL.reload();

        glClearColor(32.0/255.0, 32.0/255.0, 32.0/255.0, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        SDL_GL_SwapWindow(window);
        initEvents(apprication);
    }

    void writeVersion(){
        import std.stdio, std.conv;
        writefln("Vendor:   %s",   to!string(glGetString(GL_VENDOR)));
        writefln("Renderer: %s",   to!string(glGetString(GL_RENDERER)));
        writefln("Version:  %s",   to!string(glGetString(GL_VERSION)));
        writefln("GLSL:     %s\n", to!string(glGetString(GL_SHADING_LANGUAGE_VERSION)));
    };

    void pollEvents(){
        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
                case SDL_QUIT:
                    _shouldClose = true;
                    break;

                case SDL_KEYDOWN:
                    events.notifyKeyPressed(event.key.keysym.sym );
                    break;
                case SDL_KEYUP:
                    events.notifyKeyReleased(event.key.keysym.sym );
                    break;
                case SDL_MOUSEMOTION:
                    import std.math;
                    int button = cast(int)fmax(0, log2( cast(float)event.motion.state*2));
                    events.notifyMouseMoved(event.motion.x, event.motion.y, button);
                    break;
                case SDL_MOUSEBUTTONDOWN:
                    events.notifyMousePressed(event.button.x, event.button.y, event.button.button);
                    break;
                case SDL_MOUSEBUTTONUP:
                    events.notifyMouseReleased(event.button.x, event.button.y, event.button.button);
                    break;

                case SDL_WINDOWEVENT_SIZE_CHANGED:
                    armos.graphics.currentRenderer.resize();
                    import std.stdio;
                    "resize".writeln;
                    // events.notifyMouseReleased(event.button.x, event.button.y, event.button.button);
                    break;

                default:
                    // events.notify...
                    break;
            }
        }
    }

    void close(){
        SDL_GL_DeleteContext(glcontext); 
        closeWindow();
    }

    private void closeWindow(){
        SDL_DestroyWindow(window);
        SDL_Quit();
    };	

    void update(){
        SDL_GL_SwapWindow(window);
    }

    armos.math.Vector2i size(){
        int w, h;
        SDL_GetWindowSize(window, &w, &h);
        // _windowSize = armos.math.Vector2i(w, h);
        // return _windowSize;
        return armos.math.Vector2i(w, h);
    }
}

/++
GLFWを利用したWindowです．armosではデフォルトでこのclassを元にWindowが生成されます．
+/
class GLFWWindow : Window{
    import derelict.glfw3.glfw3;
    mixin BaseWindow;

    public{
        /++
            Params:
            apprication = Windowとひも付けされるアプリケーションです．
            +/
            this(ref armos.app.BaseApp apprication){
                DerelictGL.load();
                DerelictGLFW3.load();

                if( !glfwInit() ){}

                glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
                glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

                window = glfwCreateWindow(640, 480, cast(char*)_name, null, null);
                if(!window){close;}

                glfwMakeContextCurrent(window);

                DerelictGL.reload();

                initEvents(apprication);
                initGLFWEvents();

                glfwSwapInterval(0);
                glfwSwapBuffers(window);
            }

        /++
            Windowのサイズを返します．
            +/
            armos.math.Vector2i size(){
                auto vec = armos.Vector2i();
                glfwGetWindowSize(window, &vec[0], &vec[1]);
                return vec;
            }

        /++
            イベントが発生している場合，登録されたイベントを実行します
            +/
            void pollEvents(){
                glfwPollEvents();
            }

        /++
            Windowを更新します．
            +/
            void update(){
                // glFlush();
                // glFinish();
                glfwSwapBuffers(window);
                _shouldClose = cast(bool)glfwWindowShouldClose(window);
            }

        /++
            Windowを閉じます．
            +/
            void close(){
                _shouldClose = true;
                glfwTerminate();
            }

        void name(in string str){
            import std.string;
            _name = str;
            glfwSetWindowTitle(window, str.toStringz);
        }
    }//public

    private{
        GLFWwindow* window;

        static extern(C) void keyCallbackFunction(GLFWwindow* window, int key, int scancode, int action, int mods){
            if(action == GLFW_PRESS){
                currentWindow.events.notifyKeyPressed(key);
            }else if(action == GLFW_RELEASE){
                currentWindow.events.notifyKeyReleased(key);
            }
        }

        static extern(C) void cursorPositionFunction(GLFWwindow* window, double xpos, double ypos){
            currentWindow.events.notifyMouseMoved(cast(int)xpos, cast(int)ypos, 0);
        }

        static extern(C ) void mouseButtonFunction(GLFWwindow* window, int button, int action, int mods){
            double xpos, ypos;
            glfwGetCursorPos(window, &xpos, &ypos);

            if(action == GLFW_PRESS){
                currentWindow.events.notifyMousePressed(cast(int)xpos, cast(int)ypos, button);
            }else if(action == GLFW_RELEASE){
                currentWindow.events.notifyMouseReleased(cast(int)xpos, cast(int)ypos, button);
            }
        }

        static extern(C ) void resizeWindowFunction(GLFWwindow* window, int width, int height){
            armos.graphics.currentRenderer.resize();
        }

        void initGLFWEvents(){
            // glfwSetKeyCallback(window, &keyCallbackFunction);
            glfwSetKeyCallback(window, cast(GLFWkeyfun)&keyCallbackFunction);
            glfwSetCursorPosCallback(window, cast(GLFWcursorposfun)&cursorPositionFunction);
            glfwSetMouseButtonCallback(window, cast(GLFWmousebuttonfun)&mouseButtonFunction);
            glfwSetWindowSizeCallback(window, cast(GLFWwindowsizefun)&resizeWindowFunction);
        }
    }//private
}

/++
現在のWindowを返す関数です．
+/
armos.app.Window currentWindow(){
    return armos.app.mainLoop.window;
}

/++
現在のWindowの大きさを返す関数です．
+/
armos.math.Vector2i windowSize(){
    return currentWindow.size;
}

/++
現在のWindowのアスペクト比を返す関数です．
+/
float windowAspect(){
    return currentWindow.aspect;
}

/++
+/
void windowTitle(in string str){
    currentWindow.name = str;
}

/++
+/
string windowTitle(){
    return currentWindow.name;
}
