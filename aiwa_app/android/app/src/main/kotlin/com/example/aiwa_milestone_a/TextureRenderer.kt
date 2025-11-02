package com.example.aiwa_milestone_a

import android.graphics.Bitmap
import android.opengl.GLES20
import android.opengl.GLUtils
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

/**
 * Helper class to render a Bitmap to an OpenGL texture, which can then be rendered to a Surface.
 * This uses OpenGL ES 2.0.
 */
class TextureRenderer {
    private val TAG = "TextureRenderer"
    
    private var program = 0
    private var textureId = 0
    private var aPositionHandle = 0
    private var aTexCoordHandle = 0
    private var uTextureHandle = 0
    
    private var vertexBuffer: FloatBuffer
    private var texCoordBuffer: FloatBuffer
    
    // Vertex shader - simple pass-through
    private val vertexShaderCode = """
        attribute vec4 aPosition;
        attribute vec2 aTexCoord;
        varying vec2 vTexCoord;
        void main() {
            gl_Position = aPosition;
            vTexCoord = aTexCoord;
        }
    """.trimIndent()
    
    // Fragment shader - texture sampling
    private val fragmentShaderCode = """
        precision mediump float;
        varying vec2 vTexCoord;
        uniform sampler2D uTexture;
        void main() {
            gl_FragColor = texture2D(uTexture, vTexCoord);
        }
    """.trimIndent()
    
    // Vertices for a full-screen quad
    private val vertices = floatArrayOf(
        -1.0f, -1.0f,  // bottom left
         1.0f, -1.0f,  // bottom right
        -1.0f,  1.0f,  // top left
         1.0f,  1.0f   // top right
    )
    
    // Texture coordinates (flipped vertically for correct orientation)
    private val texCoords = floatArrayOf(
        0.0f, 1.0f,  // bottom left
        1.0f, 1.0f,  // bottom right
        0.0f, 0.0f,  // top left
        1.0f, 0.0f   // top right
    )
    
    init {
        // Initialize vertex buffer
        vertexBuffer = ByteBuffer.allocateDirect(vertices.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(vertices)
        vertexBuffer.position(0)
        
        // Initialize texture coordinate buffer
        texCoordBuffer = ByteBuffer.allocateDirect(texCoords.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(texCoords)
        texCoordBuffer.position(0)
    }
    
    /**
     * Initializes the renderer. Must be called on the OpenGL thread.
     */
    fun surfaceCreated() {
        // Create shader program
        program = createProgram(vertexShaderCode, fragmentShaderCode)
        if (program == 0) {
            throw RuntimeException("Failed to create shader program")
        }
        
        // Get handles to shader attributes and uniforms
        aPositionHandle = GLES20.glGetAttribLocation(program, "aPosition")
        checkGlError("glGetAttribLocation aPosition")
        if (aPositionHandle == -1) {
            throw RuntimeException("Could not get attrib location for aPosition")
        }
        
        aTexCoordHandle = GLES20.glGetAttribLocation(program, "aTexCoord")
        checkGlError("glGetAttribLocation aTexCoord")
        if (aTexCoordHandle == -1) {
            throw RuntimeException("Could not get attrib location for aTexCoord")
        }
        
        uTextureHandle = GLES20.glGetUniformLocation(program, "uTexture")
        checkGlError("glGetUniformLocation uTexture")
        if (uTextureHandle == -1) {
            throw RuntimeException("Could not get uniform location for uTexture")
        }
        
        // Create texture
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        checkGlError("glGenTextures")
        
        textureId = textures[0]
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        checkGlError("glBindTexture")
        
        // Set texture parameters
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        checkGlError("glTexParameter")
        
        Log.d(TAG, "Surface created, shader program initialized")
    }
    
    /**
     * Draws a bitmap to the current GL surface.
     * 
     * @param bitmap The bitmap to draw
     * @param width Surface width
     * @param height Surface height
     */
    fun drawBitmap(bitmap: Bitmap, width: Int, height: Int) {
        // Set viewport
        GLES20.glViewport(0, 0, width, height)
        checkGlError("glViewport")
        
        // Clear the screen
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        checkGlError("glClear")
        
        // Use our shader program
        GLES20.glUseProgram(program)
        checkGlError("glUseProgram")
        
        // Bind texture and upload bitmap
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        checkGlError("glBindTexture")
        
        // Upload bitmap to texture
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
        checkGlError("texImage2D")
        
        // Set texture uniform
        GLES20.glUniform1i(uTextureHandle, 0)
        checkGlError("glUniform1i")
        
        // Enable vertex arrays
        GLES20.glEnableVertexAttribArray(aPositionHandle)
        GLES20.glEnableVertexAttribArray(aTexCoordHandle)
        checkGlError("glEnableVertexAttribArray")
        
        // Set vertex data
        vertexBuffer.position(0)
        GLES20.glVertexAttribPointer(aPositionHandle, 2, GLES20.GL_FLOAT, false, 0, vertexBuffer)
        checkGlError("glVertexAttribPointer aPosition")
        
        texCoordBuffer.position(0)
        GLES20.glVertexAttribPointer(aTexCoordHandle, 2, GLES20.GL_FLOAT, false, 0, texCoordBuffer)
        checkGlError("glVertexAttribPointer aTexCoord")
        
        // Draw the quad
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        checkGlError("glDrawArrays")
        
        // Disable vertex arrays
        GLES20.glDisableVertexAttribArray(aPositionHandle)
        GLES20.glDisableVertexAttribArray(aTexCoordHandle)
    }
    
    /**
     * Releases resources. Must be called on the OpenGL thread.
     */
    fun release() {
        if (textureId != 0) {
            val textures = intArrayOf(textureId)
            GLES20.glDeleteTextures(1, textures, 0)
            textureId = 0
        }
        
        if (program != 0) {
            GLES20.glDeleteProgram(program)
            program = 0
        }
        
        Log.d(TAG, "TextureRenderer released")
    }
    
    /**
     * Creates a shader program from vertex and fragment shader source code.
     */
    private fun createProgram(vertexSource: String, fragmentSource: String): Int {
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource)
        if (vertexShader == 0) {
            return 0
        }
        
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource)
        if (fragmentShader == 0) {
            return 0
        }
        
        var program = GLES20.glCreateProgram()
        checkGlError("glCreateProgram")
        if (program == 0) {
            Log.e(TAG, "Could not create program")
            return 0
        }
        
        GLES20.glAttachShader(program, vertexShader)
        checkGlError("glAttachShader")
        GLES20.glAttachShader(program, fragmentShader)
        checkGlError("glAttachShader")
        GLES20.glLinkProgram(program)
        checkGlError("glLinkProgram")
        
        val linkStatus = IntArray(1)
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0)
        if (linkStatus[0] != GLES20.GL_TRUE) {
            Log.e(TAG, "Could not link program: ")
            Log.e(TAG, GLES20.glGetProgramInfoLog(program))
            GLES20.glDeleteProgram(program)
            program = 0
        }
        
        return program
    }
    
    /**
     * Loads and compiles a shader.
     */
    private fun loadShader(shaderType: Int, source: String): Int {
        var shader = GLES20.glCreateShader(shaderType)
        checkGlError("glCreateShader type=$shaderType")
        
        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)
        
        val compiled = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0)
        if (compiled[0] == 0) {
            Log.e(TAG, "Could not compile shader $shaderType:")
            Log.e(TAG, " " + GLES20.glGetShaderInfoLog(shader))
            GLES20.glDeleteShader(shader)
            shader = 0
        }
        
        return shader
    }
    
    /**
     * Checks for GL errors and throws an exception if one is found.
     */
    private fun checkGlError(op: String) {
        val error = GLES20.glGetError()
        if (error != GLES20.GL_NO_ERROR) {
            val errorMsg = "$op: glError 0x${Integer.toHexString(error)}"
            Log.e(TAG, errorMsg)
            throw RuntimeException(errorMsg)
        }
    }
}

