struct V2P {
    float4 pos : SV_Position;
    float3 color : COLOR0;
};

struct Vertex {
    float3 position;
    float3 color;
};

static const Vertex VERTICES[3] = {
    { { -0.5f, -0.5f,  0.0f }, { 1.0f, 0.0f, 0.0f } },
    { { -0.5f,  0.5f,  0.0f }, { 0.0f, 1.0f, 0.0f } },
    { {  0.5f,  0.5f,  0.0f }, { 0.0f, 0.0f, 1.0f } }
};

[shader("vertex")]
V2P vertexmain(uint vertex_index: SV_VertexID) {
    let vertex = VERTICES[vertex_index];
    
    V2P output;
    output.pos = float4(vertex.position, 1.0);
    output.color = vertex.color;
    
    return output;
}

struct PSOutput {
    [vk_location(0)]
    float4 frag_color : COLOR0;
};

[shader("fragment")]
PSOutput fragmentmain(V2P input) {
    PSOutput output;
    output.frag_color = float4(input.color, 1.0);
    return output;
}
