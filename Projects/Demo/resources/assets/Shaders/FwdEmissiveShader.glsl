<VERTEX>
	#version 330 core
	#include "Shaders/CommonSharedVars.glsl"
	
	in vec3 position;
	in vec3 normal;
	in vec3 tangent;
	in vec2 texcoord;
	
	out vec3 Position;
	out vec3 Normal;
	out vec3 Tangent;
	out vec2 Texcoord;
	
	uniform mat4 model;
	
	void main()
	{
		Texcoord = texcoord;
		
		mat3 normMat = inverse(mat3(model));
		normMat = transpose(normMat);
		Normal = normalize(normMat*normal);
		Tangent = normalize(normMat*tangent);
		
		vec4 pos = model*vec4(position, 1.0);
		Position = vec3(pos.x, pos.y, pos.z);
		gl_Position = viewProjection *pos;
	}
</VERTEX>
<FRAGMENT>
	#version 330 core
	
	#include "Shaders/Common.glsl"
	
	in vec3 Position;
	in vec3 Normal;
	in vec3 Tangent;
	in vec2 Texcoord;
	
	layout (location = 0) out vec4 outColor;
	layout (location = 1) out vec4 brightColor;
	
	uniform vec3 color;
	
	void main()
	{
		vec3 finalCol = clamp(color, 0.0, maxExposure+Texcoord.x+Normal.x+Tangent.x);	
		outColor = vec4(finalCol, 1.0);
	}
</FRAGMENT>