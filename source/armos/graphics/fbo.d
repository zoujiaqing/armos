module armos.graphics.fbo;
import armos.graphics;
import derelict.opengl3.gl;
import armos.math.vector;

/++
Frame Buffer Objectを表すclassです．
+/
class Fbo{
    public{
        /++
            +/
            this(){
                this(armos.app.currentWindow.size);
            }

        /++
            +/
            this(in armos.math.Vector2i size){
                this(size[0], size[1]);
            }

        /++
            +/
            this(in int width, in int height){
                glGenFramebuffers(1, cast(uint*)&fboID_);

                _colorTexture = new armos.graphics.Texture;
                _colorTexture.allocate(width, height, armos.graphics.ColorFormat.RGBA);

                _depthTexture= new armos.graphics.Texture;
                _depthTexture.allocate(width, height, armos.graphics.ColorFormat.Depth);

                float x = width;
                float y = height;
                rect.primitiveMode = armos.graphics.PrimitiveMode.TriangleStrip;

                _colorTexture.begin;
                rect.addTexCoord(0, 1);rect.addVertex(0, 0, 0);
                rect.addTexCoord(0, 0);rect.addVertex(0, y, 0);
                rect.addTexCoord(1, 1);rect.addVertex(x, 0, 0);
                rect.addTexCoord(1, 0);rect.addVertex(x, y, 0);
                _colorTexture.end;

                rect.addIndex(0);
                rect.addIndex(1);
                rect.addIndex(2);
                rect.addIndex(3);

                glGetIntegerv(GL_FRAMEBUFFER_BINDING, &savedFboID_);
                glBindFramebuffer(GL_FRAMEBUFFER, fboID_);

                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _colorTexture.id, 0);
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,  GL_TEXTURE_2D, _depthTexture.id, 0);
                glBindFramebuffer(GL_FRAMEBUFFER, savedFboID_);
            }

        /++
            FBOへの描画処理を開始します．
            +/
            void begin(){
                glGetIntegerv(GL_FRAMEBUFFER_BINDING, &savedFboID_);
                glBindFramebuffer(GL_FRAMEBUFFER, fboID_);
            }

        /++
            FBOへの描画処理を終了します．
            +/
            void end(){
                glBindFramebuffer(GL_FRAMEBUFFER, savedFboID_);
            }

        /++
            FBOのIDを返します．
            +/
            int id()const{
                return fboID_;
            }

        /++
            FBOを描画します．
            +/
            void draw(){
                _colorTexture.begin;
                rect.drawFill();
                _colorTexture.end;
            }

        /++
            FBOをリサイズします．
            Params:
            size = リサイズ後のサイズ
            +/
            void resize(in armos.math.Vector2i size){
                begin;
                rect.vertices[1].y = size[1];
                rect.vertices[2].x = size[0];
                rect.vertices[3].y = size[1];
                rect.vertices[3].x = size[0];
                _colorTexture.resize(size);
                _depthTexture.resize(size);
                end;
            }

        // void draw(in armos.math.Vector2f position, in armos.math.Vector2f size){
        //	 draw(position[0], position[1], size[0], size[1]);
        // }
    }//public

    private{
        int savedFboID_=0;
        int fboID_ = 0;
        armos.graphics.Texture _colorTexture;
        armos.graphics.Texture _depthTexture;
        armos.graphics.Mesh rect = new armos.graphics.Mesh;
    }//private
}
