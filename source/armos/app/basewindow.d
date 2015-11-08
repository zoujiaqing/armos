module armos.app.basewindow;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;
import armos.events;
import armos.app;
class BaseWindow{
	private SDL_Window* window;
	private string name;
	private armos.app.baseapp.BaseApp* app;
	private armos.events.CoreEvents core_events;
	bool shouldClose = false;
	this(ref armos.app.baseapp.BaseApp app){
		this.app = &app;
		core_events = new armos.events.CoreEvents;
		assert(core_events);
		
		armos.events.addListener(core_events.setup, app, &app.setup);
		armos.events.addListener(core_events.update, app, &app.update);
		armos.events.addListener(core_events.draw, app, &app.draw);
		armos.events.addListener(core_events.keyPressed, app, &app.keyPressed);
	}
	armos.events.CoreEvents* events(){
		assert(core_events);
		return &core_events;
	}
	
	void close(){
		closeWindow();
		events.notifyExit();
	};
	
	void closeWindow(){
		SDL_DestroyWindow(window);
		SDL_Quit();
	};	
	
	void pollEvents(){
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
				case SDL_QUIT:
					shouldClose = true;
					break;
					
				case SDL_KEYDOWN:
					events.notifyKeyPressed(event.key.keysym.sym );
					break;
				case SDL_KEYUP:
					events.notifyKeyReleased(event.key.keysym.sym );
					break;
					
				default:
					// events.notify...
					break;
			}
		}
	}
}

class WindowSettings{
	int width;
	int height;
	// position
	bool isPositionSet;
}

class BaseGLWindow : BaseWindow{
	SDL_GLContext glcontext;
	
	this(ref armos.app.BaseApp apprication){
		DerelictSDL2.load();
		DerelictGL.load();
		SDL_Init(SDL_INIT_VIDEO);
		window = SDL_CreateWindow(
				cast(char*)name,
				SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
				800, 600,
				SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE
				);
		
		glcontext = SDL_GL_CreateContext(window);
		glClearColor(32.0/255.0, 32.0/255.0, 32.0/255.0, 1);
		glClear(GL_COLOR_BUFFER_BIT);
		
		SDL_GL_SwapWindow(window);
		super(apprication);
	}
	override void close(){
		SDL_GL_DeleteContext(glcontext); 
		closeWindow();
	}
	void update(){
		SDL_GL_SwapWindow(window);
	}
}

armos.app.BaseGLWindow* getCurrentWindow(){
	return &armos.app.mainLoop.window;
}
