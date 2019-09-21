#pragma once

#include <map>
#include <glad/glad.h>


// forward declarations
class ShaderData;
class TextureData;

template<typename T>
class Uniform;


//---------------------------------
// RenderState
//
// CPU representation of the OpenGL state - helps avoiding sending too many calls to the GPU
//
class RenderState
{
public:

	// init deinit
	//--------------
	RenderState() = default;

	void Initialize();

	// State changes
	//--------------
	void SetDepthEnabled(bool enabled);
	void SetBlendEnabled(bool enabled);
	void SetBlendEnabled(bool enabled, uint32 index);
	void SetBlendEnabled(const std::vector<bool> &blendBuffers);
	void SetStencilEnabled(bool enabled);
	void SetCullEnabled(bool enabled);

	void SetSeamlessCubemapsEnabled(bool enabled);

	void SetFaceCullingMode(GLenum cullMode);
	void SetBlendEquation(GLenum equation);
	void SetBlendFunction(GLenum sFactor, GLenum dFactor);

	void SetViewport(ivec2 pos, ivec2 size);
	void GetViewport(ivec2 &pos, ivec2 &size);

	void SetClearColor(vec4 col);

	void SetShader(ShaderData const* pShader);

	void BindFramebuffer(GLuint handle);
	void BindReadFramebuffer(GLuint handle);
	void BindDrawFramebuffer(GLuint handle);

	void BindRenderbuffer(GLuint handle);

	void SetActiveTexture(uint32 unit);
	void BindTexture(GLenum target, GLuint handle);

	//Makes sure that a texture is bound to a units target for shading, 
	//only changes active texture unit if the texture was not bound yet
	void LazyBindTexture(uint32 unit, GLenum target, GLuint handle);

	void BindVertexArray(GLuint vertexArray);
	void BindBuffer(GLenum target, GLuint buffer);

	void SetLineWidth(float const lineWidth);

	//Draw Calls
	//--------------
	void DrawArrays(GLenum mode, uint32 first, uint32 count);
	void DrawElements(GLenum mode, uint32 count, GLenum type, const void * indices);
	void DrawElementsInstanced(GLenum mode, uint32 count, GLenum type, const void * indices, uint32 primcount);

	// other commands
	//--------------
	void Flush() const;
	void Clear(GLbitfield mask) const;

	void GenerateVertexArrays(GLsizei n, GLuint *arrays) const;
	void GenerateBuffers(GLsizei n, GLuint *buffers) const;

	void DeleteVertexArrays(GLsizei n, GLuint *arrays) const;
	void DeleteBuffers(GLsizei n, GLuint *buffers) const;

	void SetBufferData(GLenum target, GLsizeiptr size, const GLvoid* data, GLenum usage) const;
	void SetVertexAttributeArrayEnabled(GLuint index, bool enabled) const; // could at some point be a member on VertexArray data object

	void DefineVertexAttributePointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, GLvoid const* pointer) const;
	void DefineVertexAttribIPointer(GLuint index, GLint size, GLenum type, GLsizei stride, GLvoid const* pointer) const;
	void DefineVertexAttribDivisor(GLuint index, GLuint divisor) const;

	void* MapBuffer(GLenum target, GLenum access) const;
	void UnmapBuffer(GLenum target) const;

	uint32 GenerateTexture() const;
	void DeleteTexture(uint32& handle) const;
	void SetTextureData(TextureData& texture, void* data);
	void SetTextureParams(TextureData const& texture, uint8& mipLevels, TextureParameters& prev, TextureParameters const& next, bool const force);

	GLuint CreateShader(GLenum shaderType) const;
	GLuint CreateProgram() const;
	void DeleteShader(GLuint shader);
	void DeleteProgram(GLuint program);

	void SetShaderSource(GLuint shader, GLsizei count, GLchar const **string, int32* length) const;
	void CompileShader(GLuint shader) const;
	void BindFragmentDataLocation(GLuint program, GLuint colorNumber, std::string const& name) const;
	void AttachShader(GLuint program, GLuint shader) const;
	void LinkProgram(GLuint program) const;

	void GetShaderIV(GLuint shader, GLenum pname, GLint *params) const;
	void GetShaderInfoLog(GLuint shader, GLsizei maxLength, GLsizei *length, GLchar *infoLog) const;

	void GetProgramIV(GLuint program, GLenum pname, GLint *params) const;
	void GetActiveUniform(GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name) const;
	void GetActiveAttribute(GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name) const;

	void UploadUniform(const Uniform<bool> &uniform);
	void UploadUniform(const Uniform<int32> &uniform);
	void UploadUniform(const Uniform<uint32> &uniform);
	void UploadUniform(const Uniform<float> &uniform);
	void UploadUniform(const Uniform<vec2> &uniform);
	void UploadUniform(const Uniform<vec3> &uniform);
	void UploadUniform(const Uniform<vec4> &uniform);
	void UploadUniform(const Uniform<mat3> &uniform);
	void UploadUniform(const Uniform<mat4> &uniform);

	void InitUniform(uint32 const program, Uniform<bool> &uniform);
	void InitUniform(uint32 const program, Uniform<int32> &uniform);
	void InitUniform(uint32 const program, Uniform<uint32> &uniform);
	void InitUniform(uint32 const program, Uniform<float> &uniform);
	void InitUniform(uint32 const program, Uniform<vec2> &uniform);
	void InitUniform(uint32 const program, Uniform<vec3> &uniform);
	void InitUniform(uint32 const program, Uniform<vec4> &uniform);
	void InitUniform(uint32 const program, Uniform<mat3> &uniform);
	void InitUniform(uint32 const program, Uniform<mat4> &uniform);

	void GenFramebuffers(GLsizei n, GLuint *ids) const;
	void DeleteFramebuffers(GLsizei n, GLuint *ids) const;

	void GenRenderBuffers(GLsizei n, GLuint *ids) const;
	void DeleteRenderBuffers(GLsizei n, GLuint *ids) const;

	void SetRenderbufferStorage(GLenum format, ivec2 const dimensions) const;

	void LinkTextureToFbo(uint8 const attachment, uint32 const texHandle, int32 const level) const; 
	void LinkTextureToFbo2D(uint8 const attachment, uint32 const texTarget, uint32 const texHandle, int32 const level) const; // link to current draw FB with a color attachment
	void LinkTextureToFboDepth(uint32 const texTarget, uint32 const texHandle) const;

	void LinkRenderbufferToFbo(GLenum const attachment, uint32 const rboHandle) const;

	void SetDrawBufferCount(size_t count) const;
	void SetReadBufferEnabled(bool const val) const;

	void SetPixelUnpackAlignment(int32 const val) const;

private:

	void EnOrDisAble(bool &state, bool enabled, GLenum glState);

	//The index should be validated before calling this function, only blend and scissor test can be larger than 0
	//the index for blending must be smaller than max draw buffers too
	void EnOrDisAbleIndexed(std::vector<bool> &state, bool enabled, GLenum glState, uint32 index);

	uint32 const GetTexTarget(E_TextureType const type) const;

	GLuint m_ReadFramebuffer = 0;
	GLuint m_DrawFramebuffer = 0;

	GLuint m_Renderbuffer = 0u;

	int32 m_MaxDrawBuffers; //Depends on gpu and drivers

	bool m_DepthTestEnabled = false;

	bool m_CullFaceEnabled = false;
	GLenum m_CullFaceMode = GL_BACK;
	
	bool m_StencilTestEnabled = false;

	bool m_SeamlessCubemapsEnabled = false;

	bool m_BlendEnabled = false;
	bool m_IndividualBlend = false;
	std::vector<bool> m_BlendEnabledIndexed;
	GLenum m_BlendEquationRGB = GL_FUNC_ADD;
	GLenum m_BlendEquationAlpha = GL_FUNC_ADD;
	GLenum m_BlendFuncSFactor = GL_ONE;
	GLenum m_BlendFuncDFactor = GL_ZERO;

	ivec2 m_ViewportPosition = ivec2(0);
	ivec2 m_ViewportSize; //initialize with values used during context creation

	vec4 m_ClearColor = vec4(0);

	ShaderData const* m_pBoundShader = nullptr;

	uint32 m_ActiveTexture = 0;
	int32 m_NumTextureUnits; //depends on gpu and drivers
	std::vector<std::map<GLenum, GLuint> > m_pTextureUnits; // #todo: in the future, abstract texture data here to support all types of textures

	GLuint m_VertexArray = 0;
	std::map<GLenum, GLuint> m_BufferTargets;

	float m_LineWidth = 1.f;
};